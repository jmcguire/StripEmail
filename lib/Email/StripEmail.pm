package Email::StripEmail;

use strict;
use warnings;

=head1 NAME

Email::StripEmail - Removes quoted replies from an email.

=head1 VERSION

version 0.50

=cut

use Carp;
use Exporter 'import';
our @EXPORT    = qw( strip_email );
our @EXPORT_OK = qw( strip_email_quotedreply
                     strip_email_signature
                     strip_email_branding );
our $VERSION = '0.50'; 

#use List::Util qw/first/;

##
## Inits
##

our $REMOVED_EMAIL_MESSAGE    = '';
our $REMOVED_SIG_MESSAGE      = '';
our $REMOVED_BRANDING_MESSAGE = '';


=head1 SYNOPSIS

    use Email::StripEmail qw(strip_email strip_email_signature);

    my $email = <<END_OF_EMAIL;
    On Thursday, Jon wrote:
    > I bought a new laptop.
    > I like it.

    That's good!

    --
    Jim, perlguy
    END_OF_EMAIL

    my $email_stripped_all = strip_email($email);
    my $email_stripped_of_sig = strip_email_signature($email);

    # $email_stripped_all is:
    #
    #     That's good!
    #
    # $email_stripped_of_sig is:
    # 
    #     On Thusrday, Jon wrote:
    #     > I bought a new laptop.
    #     > I like it.
    # 
    #     That's good!
    # 

=head1 DESCRIPTION

This software will remove quoted replies, signatures, and branding lines from an
email.  (This functionality works similarly to how Google hides quoted replies
in Groups and Gmail.)  If you want to only hide one of those nuisances, import
just the relevant function.  The available functions are:

    strip_email              <-- imported by default
    strip_email_quotedreply
    strip_email_signature
    strip_email_branding

Each function takes in one string as an argument, which should be the body of
the email.

Each function returns one string, the modified email.  If it doesn't modify
anything, then it will just return the original email.

=cut


=head2 strip_email( $email )

strip_email basically just executes these three in turn:

    strip_email_signature
    strip_email_branding
    strip_email_quotedreply

It will return any stripped email it comes up with.  It tries stripping
everything, but if that doesn't work, then it tries stripping just the
signature and branding.

=cut

sub strip_email
{
    my ($body) = @_;

    return unless $body;

    my @new_body = split(/\n/, $body);

    ## first try the two easy things to strip
    @new_body = _strip_signature(@new_body);
    @new_body = _strip_branding(@new_body);
    my $new_body = join("\n",@new_body);

    ## now try the difficult one, the quoted email
    my @new_body2 = _strip_quoted_reply(@new_body);
    my $new_body2 = join("\n",@new_body2);

    ## strip empty lines at the beginning and end
    s/^\s*\n//gs foreach ($new_body, $new_body2);
    s/[\s\n]$//gs foreach ($new_body, $new_body2);

    ## return anything that looks like it worked, othewise just return the
    ## original
    ## ("worked" is defined as anything at least two letters/numbers long)
    return $new_body2 if $new_body2 =~ /[\w\d]{2}/;
    return $new_body  if $new_body  =~ /[\w\d]{2}/;
    return $body;
} 


=head2 strip_email_quotedreply( $email )

strip_email_quotedreply will only strip out a quoted reply.  It attempts to
guess at where an email begins and what quote marks, if any, are used.

If we find that the sender broke the quoted reply into parts and put comments in
between each part, we won't strip anything out.  However, we do try to
distinguish between original comments and bad word wrapping, where a word of a
quoted email appears on its own line accidentally.

=cut

sub strip_email_quotedreply
{
    my ($body) = @_;

    my @new_body = split(/\n/, $body);
    @new_body = _strip_quoted_reply(@new_body);
    my $new_body = join("\n",@new_body);

    ## strip empy lines at the beginning and end
    s/^\s*\n//gs foreach ($new_body);
    s/[\s\n]$//gs foreach ($new_body);

    ## return it if it worked, as in at least something is there
    return $new_body if $new_body =~ /[\w\d]{2}/;
    return $body;
} 


=head2 strip_email_signature( $email )

strip_email_signature strips the signature.  It simply looks for the last line
we see with just a "--" mark, and cuts everything below it.

=cut

sub strip_email_signature
{
    my ($body) = @_;

    my @new_body = split(/\n/, $body);
    @new_body = _strip_signature(@new_body);
    my $new_body = join("\n",@new_body);

    ## strip empy lines at the beginning and end
    s/^\s*\n//gs foreach ($new_body);
    s/[\s\n]$//gs foreach ($new_body);

    return $new_body;
} 


=head2 strip_email_branding( $email )

strip_email_branding strips the email branding signature that comes from mobile
devices.  It looks like this:

    "Sent from my BlackBerry"

We will only strip one of these, the last one we see.

=cut

sub strip_email_branding
{
    my ($body) = @_;

    my @new_body = split(/\n/, $body);
    @new_body = _strip_branding(@new_body);
    my $new_body = join("\n",@new_body);

    ## strip empty lines at the beginning and end
    s/^\s*\n//gs foreach ($new_body);
    s/[\s\n]$//gs foreach ($new_body);

    return $new_body;
} 

=head1 PRIVATE SUBROUTINES

The following subroutines are not exported.

=cut

=head2 _strip_signature( @email )

Look for a traditional signature, and remove it. This is what
strip_email_signature wraps around.

=cut

sub _strip_signature
{
    my @body = @_;

    ## start from the end and work up
    for (my $i = $#body; $i > 0; $i--) {
        if ($body[$i] =~ /^--\s*$/) {
            splice(@body, $i); ## remove all lines under it
            last;
        }
    }
    
    return @body;
}


=head2 _strip_branding( @email )

Remove common branding signatures

=cut

sub _strip_branding
{
    my @body = @_;

    foreach (reverse @body) {
        s/^\s*Sent from my (?:iPhone|BlackBerry|Mobile Phone)\s*$/$REMOVED_BRANDING_MESSAGE/i
            and return @body;
    }

    return @body;
}


=head2 _strip_quoted_reply( @email )

Identify and strip the quoted reply

This function is built around finding the quoted message, we have a few
variables to keep track of certain items. Among them are orig_begin, which
points to where the quote begins, and header_last, which points to the last line
of the quote headers (which don't always exist).

Here are a couple examples:

   On Thursday, Justin wrote:   <-- $orig_begin, $header_last
   > Hello
   > I also like music.

   From: Amy                    <-- $orig_begin
   To: Steve
   Subject: Hello People!       <-- $header_last
   > Hello Steve,
   > How are you?

=cut

sub _strip_quoted_reply
{
    my @body = @_;

    my $orig_begin = _reply_message_start(@body);

    if ($orig_begin < 0) {
        ## if we can't find the beginning of the message, then at least try to find
        ## contiguous quote marks
        my $quote_mark = _quote_mark(@body);
        my @quoted_indicies = _quoted_line_indicies($quote_mark, @body);

        if ($quote_mark
            and $quoted_indicies[-1] == $quoted_indicies[0] + $#quoted_indicies
        ) {
            ## strip everything from the original begining through all the lines
            ## with the quote marks (remember that the indicies in
            ## @quoted_indicies are offset by $header_last)
            splice(@body,
                   $quoted_indicies[0],
                   $quoted_indicies[-1] - $quoted_indicies[0] + 1,
                   $REMOVED_EMAIL_MESSAGE);
        }

        return @body;
    }

    ## skip past the header lines if any exist (things like From:, To:. etc),
    ## and blank lines
    my $header_last;
    for ($header_last = $orig_begin + 1; $header_last < @body; $header_last++) {
        last unless $body[$header_last] =~ / ^ \s* [\w\s]+ : | ^\s*$ /x;
    }
    --$header_last; ## the loop above hits the line after the last one

    ## the "original message begining" might be the last lines, with no real
    ## message
    if ($header_last >= @body) {
        return @body[0..$orig_begin]; ## TODO: splice in REMOVED_REPLY
    }

    ## look at just the first non-empty line after the header, that's the one
    ## that will have our quote mark, if they exist
    #my $next_line = first { !/^\s*$/ } @body[$header_last + 1..$#body];
    #my $quote_mark = _quote_mark($next_line);

    ## find the quote marks, must exist below the header
    my $quote_mark = _quote_mark( @body[$header_last + 1..$#body] );

    ## if we didn't find any quote marks, just remove the entire bottom of the
    ## message and return
    unless ($quote_mark) {
        splice(@body, $orig_begin, $#body-$orig_begin+1, $REMOVED_EMAIL_MESSAGE);
        return @body;
    }

    #$header_last++ if ($header_last == $orig_begin);
    my @quoted_indicies = _quoted_line_indicies($quote_mark,
                                                @body[$header_last..$#body]);
    
    ## just in case something has gone horribly wrong
    unless (@quoted_indicies) {
        carp "We found a quoted line, but then were unable to find it again.";
        return @body;
    }

    ## << noted trickiness >>
    ## Test that the line numbers of the reply are contiguous.  (If there's a
    ## missing line, that means a person put a comment into the middle of a
    ## quoted reply.)
    if ($quoted_indicies[0] <= 1 and _contiguous_numbers(\@quoted_indicies)) {
        ## strip everything from the original begining through all the lines
        ## with the quote marks (remember that the indicies in @quoted_indicies
        ## are offset by $header_last)
        splice(@body,
               $orig_begin,
               $header_last + $quoted_indicies[-1] - $orig_begin + 1,
               $REMOVED_EMAIL_MESSAGE);
    } else {
        ## the reply is mixed with the original email, they're probably
        ## responding to individual points, so we should keep it intact. we
        ## could strip just the header lines, but that looks odd.
        #splice(@body, $orig_begin, $header_last - $orig_begin + 1);
    }

    ## return the stripped body
    return @body;
}


=head2 _reply_message_start( @email )

Returns the index of where the quoted message begins. If we can't find it,
return -1.

=cut

sub _reply_message_start
{
    my @body = @_;

    ## look for a line that indicates the beginning of the original email
    my @msg_start_lines = ( '^----- ?Original Message ?-----$', ## Outlook
                            '^_{32}$',                          ## also Outlook
                            '\bwrote:\s*$',                     ## Mail.app, Gmail
                            '\bwrites?:\s*$',                   ## clever people
                            'Quoth .+:\s*$',                    ## some bastard
                            '^\s*In article .+ says\.{3}\s*$',  ## custom
                            );
    my $msg_start_lines_regexp = join('|', @msg_start_lines);
    #print "REGEXP: $msg_start_lines_regexp\n\n";

    ## now we try to identify the original email
    my $orig_begin;
    for ($orig_begin = 0; $orig_begin < @body; $orig_begin++) {
        last if $body[$orig_begin] =~ /$msg_start_lines_regexp/;
        last if $body[$orig_begin] =~ /^\s*From:/;
    }

    ## return the index if it makes sense, otherwise -1
    return $orig_begin < @body ? $orig_begin : -1;
}


=head2 _quote_mark( @email )

Find the most likely quote mark. If nothing good is found, we return an empty
string.

=cut

sub _quote_mark
{
    my @body = @_;

    ## get a count of each possible quote mark
    ## (possible quote mark are things like ">", "%", "jm>", "mark!")
    ## (should we be ignoring likely code comments, like # and /* ?)
    my %mark_count;
    /^ ( \s* \w* [^'"\d\w\s] ) /x and $mark_count{$1}++ foreach @body;

    return '' unless %mark_count;

    ## get the most heavily used quote mark
    ## (note: if there is more than one possibility, we return an arbitrary
    ##        one.  obviously not the best design choice.)
    my $quote_mark = ( reverse
                       sort {$mark_count{$a} <=> $mark_count{$b}}
                       keys %mark_count
                      )[0];

    return $quote_mark;
}


=head2 _quoted_line_indicies( $quote_mark, @email )

Takes in the quote mark character, and the lines of the body that you want
checked.

Returns an array of numbers, these are indicies of lines (from the input) that
are part of the reply message

=cut

sub _quoted_line_indicies
{
    my ($quote_mark, @body) = @_;

    ## look for one or more lines that begin with our found quote mark
    my @quoted_indicies;
    for (my $i = 0; $i < @body; $i++) {
        ## keep track of the line indicies we found
        push (@quoted_indicies, $i) and next if $body[$i] =~ /^\Q$quote_mark/;

        ## look for bad wrapping, where a non-quoted word really is part of the 
        ## quoted text, but accidentally ended up on the next line due to
        ## wrapping. most of the time it's just one word, often, "wrote:".
        ## looking for more than one word is fraught with errors.
        ## (note: this will also look for empty lines between quoted reply
        ## fragments.)
        push (@quoted_indicies, $i) and next
            if (     $body[$i-1] and $body[$i-1] =~ /^\Q$quote_mark/
                 and $body[$i]   and $body[$i]   =~ /^\S*\s*$/
                 and $body[$i+1] and $body[$i+1] =~ /^\Q$quote_mark/
               );
    } 

    return @quoted_indicies;
}

=head2 _contiguous_numbers( $list_of_numbers )

Given a list of numbers, this tell you whether the numbers are contiguous.

Returns boolean, 1 or 0.

=cut

sub _contiguous_numbers
{
    my ($list_of_numbers) = @_;

    ## we just test if last number = first number + array size.
    ## note: this trick only works if there are no duplicates, and the numbers
    ## are ordered

    return $list_of_numbers->[-1] == $list_of_numbers->[0] + $#$list_of_numbers ? 1 : 0;
}

1;


=head1 DIAGNOSTICS

"We found a quoted line, but then were unable to find it again."

This should never be encountered, as it indicates a program bug.

=head1 BUGS AND LIMITATIONS

Given the vast number of non-standard reply and signature semantics,
Email::StripEmail makes a few guesses and assumptions.  These guesses and
 assumptions lead to logic errors come in two varieties.

 1) In some cases, emails will not have a quoted reply stripped out that should
    have been.
 2) More troublesome, and hopefully more rare, sometimes a reply is stripped
    that includes non-reply information.

=head1 AUTHOR

Justin McGuire <F<mcguire.justin@gmail.com>>

=head1 COPYRIGHT

  Copyright (c) 2010 Justin McGuire. All rights reserved.
  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

