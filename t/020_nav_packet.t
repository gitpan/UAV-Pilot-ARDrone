use Test::More tests => 10;
use v5.14;
use warnings;

use AnyEvent;
use UAV::Pilot::EasyEvent;
use UAV::Pilot::ARDrone::NavPacket;

my $bad_header = make_packet( '55667788' );
eval {
    local $SIG{__WARN__} = sub {}; # Temporarily suppress warnings
    UAV::Pilot::ARDrone::NavPacket->new({
        packet => $bad_header
    });
};
if( $@ && $@->isa( 'UAV::Pilot::NavPacketException::BadHeader' ) ) {
    pass( 'Caught Bad Header exception' );
    #diag( "Exception message: " . $@->error );
    cmp_ok( $@->got_header, '==', 0x88776655, "BadHeader exception has got_header value" );
}
else {
    fail( 'Did not catch Bad Header exception' );
    fail( 'Fail matching magic number, too [placeholder failure for test count]' );
}


my @STATE_TESTS = (
    {
        packet => join('',
            # These are in little-endian order
            '88776655',   # Header
            'd004804f',   # Drone state
            '336f0000',   # Sequence number
            '01000000',   # Vision flag
            # No options on this packet besides checksum
            'ffff',       # Checksum ID
            '0800',       # Checksum size
            'c1030000',   # Checksum data
        ),
        fields => {
            header        => 0x55667788,
            drone_state   => 0x4f8004d0,
            sequence_num  => 0x00006f33,
            vision_flag   => 0x00000001,
            checksum      => 0x000003c1,
            state_emergency                     => 0,
            state_communication_problem_occured => 1,
            state_adc_watchdog_delayed          => 0,
            state_control_watchdog_delayed      => 0,
            state_acquisition_thread_on         => 1,
            state_video_thread_on               => 1,
            state_nav_data_thread_on            => 1,
            state_at_codec_thread_on            => 1,
            state_pic_version_ok                => 1,
            state_cutout_system_detected        => 0,
            state_ultrasonic_sensor_deaf        => 0,
            state_too_much_wind                 => 0,
            state_angles_out_of_range           => 0,
            state_not_enough_power              => 0,
            state_timer_elapsed                 => 0,
            state_battery_too_high              => 0,
            state_battery_too_low               => 0,
            state_gyrometers_down               => 0,
            state_motors_down                   => 0,
            state_nav_data_bootstrap            => 0,
            state_nav_data_demo_only            => 1,
            state_trim_succeeded                => 0,
            state_trim_running                  => 0,
            state_trim_received                 => 1,
            state_control_received              => 1,
            state_user_feedback_on              => 0,
            state_altitude_control_active       => 1,
            state_control_algorithm             => 0,
            state_vision_enabled                => 0,
            state_video_enabled                 => 0,
            state_flying                        => 0,
        },
    },
);
foreach my $state_test (@STATE_TESTS) {
    my $packet_str  = $state_test->{packet};
    my $packet_data = make_packet( $packet_str );
    my $fields = $state_test->{fields};

    my $packet = UAV::Pilot::ARDrone::NavPacket->new({
        packet => $packet_data
    });
    isa_ok( $packet => 'UAV::Pilot::ARDrone::NavPacket' );

    cmp_ok( $packet->to_hex_string, 'eq', $packet_str, "Convert back into hex");

    my %got_fields = (
        map {
            $_ => $packet->$_,
        } keys %$fields
    );

    is_deeply( $fields, \%got_fields, "State fields correct" );
}




# Parsing Demo option
my $demo_packet_data = make_packet( join('',
    '88776655', # Header
    'd004800f', # Drone state
    '346f0000', # Sequence number
    '01000000', # Vision flag
    # Options
    '0000', # Demo ID
    '9400', # Demo Size (148 bytes)
    '00000200', # Control State (landed, flying, hovering, etc.)
    '59000000', # Battery Voltage Filtered (mV? Percentage?)
    'bf4ccccd', # Pitch (-0.8)
    '00209ec4', # Roll (4.20758336247455e-29)
    '00941a47', # Yaw
    '00000000', # Altitude (cm)
    '00000000', # Estimated linear velocity (x)
    '00000000', # Estimated linear velocity (y)
    '00000000', # Estimated linear velocity (z)
    '00000000', # Streamed Frame Index
    '000000000000000000000000', # Deprecated camera detection params
    '00000000', # Camera Detection, Type of Tag
    '0000000000000000', # Deprecated camera detection params
    # Demo tag is 64 bytes up to here.  The C code for navdata_demo_t struct is done, but 
    # we still have 84 bytes to go . . .
    '0000000000000000',
    '0000000000000000',
    '0000000000000000',
    '0000000003000000',
    '0e4f453fe9fb22bf',
    'e7ffcdbcd111233f',
    '3455453f70f5003c',
    'c67a6b3c9feab4bc',
    '3ee97f3f00000000',
    '0000000000000000',
    '10004801',
    # 148 bytes, end of demo option
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000',
    # I guess it really likes sending zeros
    'ffff',     # Checksum ID
    '0800',     # Checksum Length
    '201b0000', # Checksum Data
) );
my $demo_packet = UAV::Pilot::ARDrone::NavPacket->new({
    packet => $demo_packet_data
});
cmp_ok( $demo_packet->battery_voltage_percentage, '==', 0x59, "Battery volt parsed" );
cmp_ok( $demo_packet->pitch, '==', -0.800000011920929, "Pitch parsed" );
cmp_ok( $demo_packet->roll, '>', 2.99569025183973e-39, "Roll parsed (less than float)" );
cmp_ok( $demo_packet->roll, '<', 2.99569025183975e-39, "Roll parsed (greater than float)" );


my $demo_packet_nan_data = make_packet( join('',
    '88776655', # Header
    'd004800f', # Drone state
    '346f0000', # Sequence number
    '01000000', # Vision flag
    # Options
    '0000', # Demo ID
    '9400', # Demo Size (148 bytes)
    '00000300', # Control State
    '5c000000', # Battery Voltage Filtered
    '00408d44', # Pitch
    '00a08544', # Roll
    '00c0b847', # Yaw
    'f0030000', # Altitude
    'ffb3dbc2', # Est linear velocity (x) [***NaN***]
    '85783543', # Est linear velocity (y)
    '00000000', # Est linear velocity (z)
    # Bunch of other crap
    '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000004a44413f23e1273f14ca2d3b0bce27bf7935413f2965ddbce494a1bcfde6983cd5e77f3f3cac6fc4b5b170c30060a2c410004801', 
    # 148 bytes, end of demo option
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000',
    'ffff',     # Checksum ID
    '0800',     # Checksum Length
    '201b0000', # Checksum Data
) );
my $demo_packet_nan = UAV::Pilot::ARDrone::NavPacket->new({
    packet => $demo_packet_nan_data
});
ok( $demo_packet_nan, "Successfully parsed data with NaN" );


sub make_packet
{
    my ($hex_str) = @_;
    pack 'H*', $hex_str;
}
