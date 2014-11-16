
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR       => [ 'Erik Huelsmann <ehuels@gmail.com>', ],
    NAME         => "App::EtcTransactionManager",
    PREREQ_PM    => {
        'Config::IniFiles'      => 0,
	'File::Copy::Recursive' => 0,
        'String::ShellQuote'    => 0,
    },
    BUILD_REQUIRES => { 'Test::Simple' => 0, },
    VERSION_FROM  => 'lib/ETM.pm',
    EXE_FILES     => [ 'bin/etm', ],
    LICENSE       => 'apache_2_0',
    
);
