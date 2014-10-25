use Test::More;
use v5.14;

eval "use UAV::Pilot::Video::H264Decoder";
if( $@ ) {
    plan skip_all => "UAV::Pilot::Video::Ffmepg not installed";
}
else {
    plan tests => 10;
}

use UAV::Pilot;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Video::Mock;
use UAV::Pilot::ARDrone::Control;
use UAV::Pilot::Video::Mock::RawHandler;
use File::Temp ();
use AnyEvent;
use Test::Moose;

use constant VIDEO_DUMP_FILE => 't_data/ardrone_video_stream_dump.bin';
use constant MAX_WAIT_TIME   => 5;


package MockH264Handler;
use Moose;
with 'UAV::Pilot::Video::H264Handler';

has 'real_vid' => (
    is  => 'ro',
    isa => 'UAV::Pilot::Video::H264Decoder',
);

sub process_h264_frame
{
    my ($self, @args) = @_;
    my $real_vid = $self->real_vid;
    $real_vid->process_h264_frame( @args );
    exit 0;

    # Never get here
    return 1;
}

package MockH264Handler2;
use Moose;
with 'UAV::Pilot::Video::H264Handler';

sub process_h264_frame
{
    Test::More::pass( 'Passed stacked handler' );
}


package main;

my $display = UAV::Pilot::Video::Mock::RawHandler->new({
    cb => sub {
        my ($self, $width, $height, $decoder) = @_;
        cmp_ok( $width,  '==', 640, "Width passed" );
        cmp_ok( $height, '==', 360, "Height passed" );

        isa_ok( $decoder => 'UAV::Pilot::Video::H264Decoder' );

        my $pixels = $decoder->get_last_frame_pixels_arrayref;
        cmp_ok( ref($pixels), 'eq', 'ARRAY', "Got array ref of pixels" );
        cmp_ok( scalar(@$pixels), '==', 3, "Got 3 channels in YUV420P format" );
    },
});
my $display2 = UAV::Pilot::Video::Mock::RawHandler->new({
    cb => sub {
        pass( "Got stacked handler" );
    },
});
my $video = UAV::Pilot::Video::H264Decoder->new({
    displays => [ $display, $display2 ],
});
isa_ok( $video => 'UAV::Pilot::Video::H264Decoder' );
does_ok( $video => 'UAV::Pilot::Video::H264Handler' );

my $cv = AnyEvent->condvar;
my $mock_video = MockH264Handler->new({
    real_vid => $video,
});
my $mock_video2 = MockH264Handler2->new;
my $ardrone = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
});
my $driver_video = UAV::Pilot::ARDrone::Video::Mock->new({
    file     => VIDEO_DUMP_FILE,
    handlers => [ $mock_video2, $mock_video ],
    condvar  => $cv,
    driver   => $ardrone,
});
isa_ok( $driver_video => 'UAV::Pilot::ARDrone::Video' );

my $dev = UAV::Pilot::ARDrone::Control->new({
    driver => $ardrone,
    video  => $driver_video,
});

my $timeout_timer; $timeout_timer = AnyEvent->timer(
    after => MAX_WAIT_TIME,
    cb    => sub {
        fail( 'Did not get a frame after ' . MAX_WAIT_TIME . ' seconds' );
        fail( 'Stub failure for test count matching' ) for 1 .. 6;
        exit 1;

        # Never get here
        $timeout_timer;
    },
);

$driver_video->init_event_loop;
$cv->recv;
