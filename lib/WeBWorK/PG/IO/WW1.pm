################################################################################
# WeBWorK mod-perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO;

use strict;
use warnings;
use Exporter;
use GD;

our @ISA = qw(Exporter);
our @EXPORT = (
	'REMOTE_HOST',             # replaced with a problem envir. variable
	'REMOTE_ADDR',             # replaced with a problem envir. variable
	'includePGtext',
	'send_mail_to',
	'read_whole_problem_file',
	'read_whole_file',
	'convertPath',
	'getDirDelim',
	#'getCourseTempDirectory',  # defined in Global.pm
	'surePathToTmpFile',
	'fileFromPath',
	'directoryFromPath',
	'createFile',
	'createDirectory',
);

# The above symbols are exported into the caller's namespace. This is usually
# done so that they can be shared with a problem's safe compartment via
# WeBWorK::PG::Translator. To do this, add the symbol's name to the
# %shared_subroutine_hash hash in lib/WeBWorK/PG/Translator.pm.

=head1 Private functions (not methods) used by PGtranslator for file IO.

=cut

my $REMOTE_HOST = (defined( $ENV{'REMOTE_HOST'} ) ) ? $ENV{'REMOTE_HOST'}: 'unknown host';
my $REMOTE_ADDR = (defined( $ENV{'REMOTE_ADDR'}) ) ? $ENV{'REMOTE_ADDR'}: 'unknown address';

=head2 includePGtext

	includePGtext($string_ref, $envir_ref)

Calls C<createPGtext> recursively with the $safeCompartment variable set to 0
so that the rendering continues in the current safe compartment.  The output
is the same as the output from createPGtext. This is used in processing
some of the sample CAPA files.

=cut

sub includePGtext  {
	my $evalString = shift;
	if (ref($evalString) eq 'SCALAR') {
		$evalString = $$evalString;
	} 
	$evalString =~ s/\nBEGIN_TEXT/TEXT\(EV3\(<<'END_TEXT'\)\);/g;
	$evalString =~ s/\\/\\\\/g; # \ can't be used for escapes because of TeX conflict
	$evalString =~ s/~~/\\/g;   # use ~~ as escape instead, use # for comments
	no strict;
	eval("package main; $evalString") ;
	my $errors = $@;
	die eval(q! "ERROR in included file:\n$main::envir{probFileName}\n $errors\n"!) if $errors;
	use strict;
	return "";
}

=head2 send_mail_to

	send_mail_to($user_address,'subject'=>$subject,'body'=>$body)

	Returns: 1 if the address is ok, otherwise a fatal error is signaled using wwerror.

Sends $body to the address specified by $user_address provided that
the address appears in C<@{$Global::PG_environment{'ALLOW_MAIL_TO'}}>.

This subroutine is likely to be fragile and to require tweaking when installed
in a new environment.  It uses the unix application C<sendmail>.

=cut

sub send_mail_to {
    my $user_address = shift;   # user must be an instructor
    my %options = @_;
    my $subject = '';
       $subject = $options{'subject'} if defined($options{'subject'});
    my $msg_body = '';
       $msg_body =$options{'body'} if defined($options{'body'});
    my @mail_to_allowed_list = ();
       @mail_to_allowed_list = @{ $options{'ALLOW_MAIL_TO'} } if defined($options{'ALLOW_MAIL_TO'});
    my $out;

    # check whether user is an instructor
    my $mailing_allowed_flag =0;


     while (@mail_to_allowed_list) {
     	if ($user_address eq shift @mail_to_allowed_list ) {
     		$mailing_allowed_flag =1;
     		last;
    	}
     }
    if ($mailing_allowed_flag) {
 		## mail header text:
 		my   $email_msg ="To:  $user_address\n" .
 				"X-Remote-Host:  $REMOTE_HOST($REMOTE_ADDR)\n" .
 				"Subject: $subject\n\n" . $msg_body;
	    my $smtp = Net::SMTP->new($Global::smtpServer, Timeout=>10) ||
			warn "Couldn't contact SMTP server.";
	    $smtp->mail($Global::webmaster);

		if ( $smtp->recipient($user_address)) {  # this one's okay, keep going
	        $smtp->data( $email_msg) ||
				warn("Unknown problem sending message data to SMTP server.");
	    } else {			# we have a problem a problem with this address
		    $smtp->reset;
	        warn "SMTP server doesn't like this address: <$user_address>.";
		}
	    $smtp->quit;

    } else {

		Global::wwerror("$0","There has been an error in creating this problem.\n" .
		             "Please notify your instructor.\n\n" .
		             "Mail is not permitted to address $user_address.\n" .
		             "Permitted addresses are specified in the courseWeBWorK.ph file.",
		             "","","");
	   $out = 0;
    }

    $out;

}

=head2   read_whole_problem_file

	read_whole_problem_file($filePath);

	Returns: A reference to a string containing
	         the contents of the file.

Don't use for huge files. The file name will have .pg appended to it if it doesn't
already end in .pg.  Files may become double spaced.?  Check the join below. This is 
used in importing additional .pg files as is done in the 
sample problems translated from CAPA.

=cut

sub read_whole_problem_file {
	my $filePath = shift;
	$filePath =~s/^\s*//; # get rid of initial spaces
	$filePath =~s/\s*$//; # get rid of final spaces
	$filePath = "$filePath.pg" unless $filePath =~ /\.pg$/;
	read_whole_file($filePath);
}

sub read_whole_file {
	my $filePath = shift;
	local (*INPUT);
	open(INPUT, "<$filePath") || die "$0: readWholeProblemFile subroutine: <BR>Can't read file $filePath";
	local($/)=undef;
	my $string = <INPUT>;  # can't append spaces because this causes trouble with <<'EOF'   \nEOF construction
	close(INPUT);
	\$string;
}

=head2 convertPath

	$path = convertPath($path);

Normalizes the delimiters in the path using delimiter from C<&getDirDelim()>
which is defined in C<Global.pm>.

=cut

sub convertPath {
    return wantarray ? @_ : shift;
}

# hacks to make this program work independent of Global.pm
sub getDirDelim {
	return ("/");
}

=head2 surePathToTmpFile

	surePathToTmpFile($path)
	Returns: $path

Defined in FILE.pl

Creates all of the subdirectories between the directory specified
by C<&getCourseTempDirectory> and the address of the path.

Uses

	&createDirectory($path,$Global::tmp_directory_permission, $Global::numericalGroupID)

The path may  begin with the correct path to the temporary
directory.  Any other prefix causes a path relative to the temporary
directory to be created.

The quality of the error checking could be improved. :-)

=cut

sub surePathToTmpFile {
	&main::surePathToTmpFile;
 }

=head2 fileFromPath

	$fileName = fileFromPath($path)

Defined in C<FILE.pl>.

Uses C<&getDirDelim()> to determine the path delimiter.  Returns the last segment
of the path (after the last delimiter.)

=cut

sub fileFromPath {
	my $path = shift;
	my $delim =&getDirDelim();
	$path =  convertPath($path);
	$path =~  m|([^$delim]+)$|;
	$1;
} 

=head2 directoryFromPath


	$directoryPath = directoryFromPath($path)

Defined in C<FILE.pl>.

Uses C<&getDirDelim()> to determine the path delimiter.  Returns the initial segments
of the of the path (up to the last delimiter.)

=cut
   
sub directoryFromPath {
	my $path = shift;
	my $delim =&getDirDelim();
	$path = convertPath($path);
	$path =~ s|[^$delim]*$||;
	$path;
}

=head2 createFile

	createFile($filePath);

Calls C<FILE.pl> version of createFile with
C<createFile($filePath,0660(permission),$Global::numericalGroupID)>

=cut

sub createFile {
	my ($fileName, $permission, $numgid) = @_;
	open(TEMPCREATEFILE, ">$fileName")
		or die "Can't open $fileName: $!";
	my @stat = stat TEMPCREATEFILE;
	close(TEMPCREATEFILE);
	
	## if the owner of the file is running this script (e.g. when the file is first created)
	## set the permissions and group correctly
	if ($< == $stat[4]) {
		my $tmp = chmod($permission,$fileName)
			or warn "Can't do chmod($permission, $fileName): $!";
		chown(-1,$numgid,$fileName)
			or warn "Can't do chown($numgid, $fileName): $!";
	}
}

sub createDirectory {
	my ($dirName, $permission, $numgid) = @_;
	mkdir($dirName, $permission)
		or warn "Can't do mkdir($dirName, $permission): $!";
	chmod($permission, $dirName)
		or warn "Can't do chmod($permission, $dirName): $!";
	unless ($numgid == -1) {
		chown(-1,$numgid,$dirName)
			or warn "Can't do chown(-1,$numgid,$dirName): $!";
	}
}

1;
