#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

require 'bin/_validate.pl';

$|++;

use CPAN::Changes::Web;
use Dancer ':script';
use CPAN::Changes;
use CPAN::Mini::Visit;
use CPAN::DistnameInfo;
use Getopt::Long;

GetOptions(
    'resume|r'       => \my $resume,
    'force|f'        => \my $force,
    'minicpan|m=s'   => \my $minicpan,
    'visitopts|vo=s' => \my %visitopts,
);

my $schema = CPAN::Changes::Web::schema( 'db' );
my $scan = $schema->resultset( 'Scan' )->first;

if ( !$scan || !$resume ) {
    $scan = $schema->resultset( 'Scan' )
        ->create( { cpan_changes_version => $CPAN::Changes::VERSION } );
}
else {
    $scan->update( { cpan_changes_version => $CPAN::Changes::VERSION } );
}

my $release_rs = $schema->resultset( 'Release' );
my $release;
my $counter = 0;

CPAN::Mini::Visit->new(
    minicpan   => $minicpan || undef,
    callback   => \&parse_changelogs,
    ignore     => [ \&skip_existing ],
    prefer_bin => 1,
    %visitopts,
)->run;

print "\n";

sub skip_existing {
    my $job = shift;
    printf "\r[%05d] %-71.71s", ++$counter, $job->{ dist };

    my $distinfo = CPAN::DistnameInfo->new( $job->{ dist } );
    $release = $release_rs->find_or_new(
        {   distribution   => $distinfo->dist,
            author         => $job->{ author },
            version        => $distinfo->version || 'undef', # e.g. BCARROLL/Tk-GraphMan.zip
            dist_timestamp => DateTime->from_epoch( epoch => ( stat( $job->{ archive } ) )[ 9 ] ),
        },
        { key => 'release_key' }
    );

    my $exists = $release->in_storage;
    $release->insert if !$exists;

    # use eval to ignore possible errors via resume or forced reparsing
    eval { $scan->add_to_releases( $release ); };

    return ( !$exists || $force ) ? 0 : 1;
}

sub parse_changelogs {
    my $job = shift;

    if ( !-f 'Changes' ) {
        $release->update( { failure => 'No "Changes" file found.' } );
        return;
    }

    $release->changes_fulltext( slurp( 'Changes' ) );

    validate_changes( $release );
}

sub slurp {
    open( my $fh, '<', shift ) or die $!;
    my $content = do { local $/; <$fh> };
    close( $fh );
    return $content;
}
