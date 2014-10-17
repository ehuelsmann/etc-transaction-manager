
package ETM;

use strict;
use warnings;
use English;
use Exporter;

use Config::IniFiles;
use File::Copy qw(cp);
use File::Copy::Recursive qw(dircopy);
use File::Path qw(make_path remove_tree);
use File::Spec::Functions;
use Time::HiRes qw(gettimeofday);

use String::ShellQuote;

our $VERSION = '0.0.0';

# parameterize these in order to allow overriding them for testing
our $repo = $ENV{ETM_REPODIR} || '/var/lib/etm/repos';
our $roots = $ENV{ETM_ROOTS} || '/var/lib/etm/roots';
our $etc = $ENV{ETM_ETCDIR} || '/etc';

our $jail_access = 'use_sudo'; # any of 'require_root', 'use_sudo' or 'use_su'

our @ISA = qw(Exporter);
our @EXPORT = qw(init);


sub wrap_for_access {
    my ($command) = @_;
    my $wrapped;

    if ($jail_access eq 'use_sudo') {
        $wrapped = "sudo $command";
    }
    elsif ($jail_access eq 'use_su') {
        my $quoted = shell_quote $command;
        $wrapped = "su - -c '$quoted'";
    }
    elsif ($jail_access eq 'require_root') {
        if ($UID != 0 && $EUID != 0) {
            print "You're non-root, but root priviledges required by configuration."
        }
        $wrapped = $command;
    }

    return $wrapped;
}

sub write_version_metadata {
    my ($path, %options) = @_;

    open FH, ">" . catfile($path, 'etm-meta.yml');
    print FH <<EOF;
date: $options{date}
time: $options{time}
based_on: $options{based_on}
desc: $options{desc}
description: $options{description}
EOF


}

sub transaction_dir {
    my ($name) = @_;

    return catfile($repo, $name);
}

sub is_transaction_name {
    my ($name) = @_;

    return (-d catfile($repo, $name)
            && -f catfile($repo, $name, "etm-meta.yml"));
}

sub new_transaction_name {
    my $name = gettimeofday;

    while (is_transaction_name($name)) {
        $name = gettimeofday;
    }

    return $name;
}

sub new_jail_directory {
    my $name = gettimeofday;

    while(-d catfile($roots, $name)) {
        $name = gettimeofday;
    }

    return catfile($roots, $name);
}

sub new_transaction_from {
    my ($name) = @_;
    my $new_name = new_transaction_name;

    dircopy catfile($repo, $name), catfile($repo, $new_name)
        or die "Could not create new transaction '$repo/$new_name' from '$repo/$name'";

    return $new_name;
}

sub init {
    my ($options, @arguments) = @_;

    if (scalar(@arguments) > 0) {
        my $count = scalar(@arguments);
        &{$options->{error}}("'init' command accepts no arguments, $count given");
    }

    my $initial_transaction = new_transaction_name;
    my $initial_version = $initial_transaction;

    if (! -d $repo) {
        make_path $repo
            or die "Could not create configuration versioning repository $repo";
    }

    $initial_version = catfile($repo, $initial_version);
    make_path $initial_version
        or die "Could not create initial configuration directory $initial_version";

    system wrap_for_access "cp -rp /etc " .
        shell_quote  catfile($initial_version, 'etc');
    die "Could not copy $etc into $initial_version/etc"
        if $? != 0
; 
    write_version_metadata $initial_version, desc => 'Initial'
        or die "Could not initialize initial configuration $initial_version";

    my $new_transaction = new_transaction_from $initial_transaction;

    symlink "$repo/$new_transaction/etc", "$etc.new"
        or die "Can't create symlink $etc.new to configuration $repo/$new_transaction/etc";

    rename $etc, "$etc.saved"
        or die "Can't rename $etc to $etc.saved during initialization";
    rename "$etc.new", $etc
        or die "Can't rename $etc.new to $etc during initialization";

    return 1;
}


sub jail_setup {
    my ($transaction) = @_;
    my $jail = new_jail_directory;
    my $transaction_etc = catfile(&transaction_dir($transaction), 'etc');

    make_path $jail
        or die;

    # set up the jail
    foreach my $mountpoint ('/proc', '/sys', '/usr', '/var', '/root',
                            '/boot', '/run', '/lib', '/srv', '/dev') {
        make_path catfile($jail, $mountpoint)
            or die;

        system wrap_for_access "mount --bind $mountpoint "
            . shell_quote catfile($jail, $mountpoint)
            or die "Can't bind-mount the jail.";
    }

    # set up 
    system wrap_for_access "mount --bind " . shell_quote($transaction_etc)
        . " " . shell_quote(catfile($jail, 'etc'))
        or die "Can't mount $transaction_etc to overlap " 
               . catfile($jail, 'etc');

    return $jail;
}

sub extract_jail {
    my ($mount_line, $root) = @_;

    $mount_line =~ m!on ($root/.*) type!;
    return $1;
}

sub jail_teardown {
    my ($options, $name) = @_;
    my $error = 0;
    my $root = catfile($roots, $name);
    my @mountpoints =
        sort { $b <=> $a } # reverse sort to unmount deepest first
        grep { defined($_) } 
        map { &extract_jail($_, $root) } `mount`;

    if (scalar(@mountpoints) == 0) {
        &{$options->{error}}("No mountpoints in $root", nohelp => 1);
    }
    else {
        foreach my $mountpoint (@mountpoints) {
            system wrap_for_access "umount " . join(' ', shell_quote  $mountpoint );
            print "error unmounting $mountpoint\n"
                if $? != 0;
            $error ||= $?;
        }
    }

    if ($error) {
        print "Not deleting $root due to errors. Please remove manually.\n";
    }
    else {
        remove_tree( $root )
            if -d $root;
    }
}




1;
