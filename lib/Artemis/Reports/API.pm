package Artemis::Reports::API;

use 5.010;
use strict;
use warnings;

our $VERSION = '2.010001';

use parent 'Net::Server::Fork';

use Artemis::Reports::DPath::Mason;
use Artemis::Model 'model';
use Data::Dumper;

sub process_request
{
        my ($self) = @_;

        $self->{cmdline} = <STDIN>;
        my ($cmd, @args) = _split_cmdline( $self->{cmdline} );
        no strict 'refs';
        my $handle = "handle_$cmd";
        $self->$handle (@args);
}

sub handle_upload
{
        my ($self, $report_id, $filename, $contenttype) = @_;

        $self->{payload} = '';
        $self->{payload} .= $_ while <STDIN>;

        my $reportfile = model('ReportsDB')->resultset('ReportFile')->new({ report_id   => $report_id,
                                                                            filename    => $filename,
                                                                            filecontent => $self->{payload},
                                                                            contenttype => $contenttype || 'plain', # 'application/octet-stream',
                                                                          });
        $reportfile->insert;
}

sub handle_mason
{
        my ($self, @args) = @_;

        my $EOFMARKER;
        $EOFMARKER = $1 if $args[-1] =~ /<<(.*)/;

 READTEMPLATE:

        my $line;
        $self->{payload} = '';
        while ($line = <STDIN>)
        {
                last if ($line eq $EOFMARKER);
                $self->{payload} .= $line;
        }

 COMPILETEMPLATE:

        my $mason  = new Artemis::Reports::DPath::Mason;
        my $answer = $mason->render(template => $self->{payload});

        print $answer;
}

sub _split_cmdline
{
        my ($cmdline) = @_;

        $cmdline =~ s/^\s+//;
        my @list = split (/\s+/, $cmdline);
        shift @list; # no shebang
        return @list;
}

sub post_process_request_hook
{
        my ($self) = @_;
}

1;


=head1 NAME

Artemis::Reports::API - A simple remote network API. First line declares language. Following lines are content.


=head1 SYNOPSIS

    use Artemis::Reports::API;
    my $foo = Artemis::Reports::API->new();
    ...

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive


=cut

1; # End of Artemis::Reports::API
