etc-transaction-manager
=======================

Manage your /etc directory updates transactionaly


Goal
----

The goal of the project is to develop a tool which can be used to run
series of modifying operations on your /etc directory, transactionally.
Meaning that if you run the commands and any command fails, no
modifications will be made to the /etc directory; either by reverting
them or by not publishing them in the first place.


Design
------

The different versions of the /etc directory content are being stored
in the /var directory hierarchy under /var/lib/etm/repos. The /etc
directory is being replaced by a symlink to a directory holding the /etc
content there.

When content modifications are required, that should be done by setting
up a transaction through the 'etm' binary.  When the transaction modification
commands complete succesfully, the transaction can be made active.  Otherwise
it can be deleted/rolled back.


Development status
------------------

The application isn't usable yet.  The intent is to develop a minimal
command line interface at first, with the following functionalities:

 - Initialization of the /etc repository
 - Creation of new /etc transactions
 - Switching between active/published-on-/etc transactions

The library (but not the command line interface) currently supports
the functionality required for the first and second bullet.  However,
there are not enough tests in place for quality assurance.


Requirements
------------

Since part of the information stored in /etc will be access restricted
to the root user, the tool needs to be run either as root directly,
through 'su' or 'sudo'.  The library can be configured to run commands
through 'sudo' or 'su' if it's not being run as root directly.


Security
--------

Files get copied while maintaining the original ownership and access
mask.  Any file strictly accessible by root in the original location
will be strictly accessible by root in the transaction locations.

