package CPAN::Changes::Web::Schema::Result::ScanReleaseJoin;

use strict;
use warnings;

use base qw( DBIx::Class );

__PACKAGE__->load_components( qw( Core ) );
__PACKAGE__->table( 'scan_release_join' );
__PACKAGE__->add_columns(
    scan_id => {
        data_type      => 'bigint',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    release_id => {
        data_type      => 'bigint',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);
__PACKAGE__->set_primary_key( qw( scan_id release_id ) );
__PACKAGE__->belongs_to(
    scan => 'CPAN::Changes::Web::Schema::Result::Scan',
    'scan_id'
);
__PACKAGE__->belongs_to(
    release => 'CPAN::Changes::Web::Schema::Result::Release',
    'release_id'
);

1;
