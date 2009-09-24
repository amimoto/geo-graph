use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Graph',
    VERSION_FROM      => 'lib/Geo/Graph.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
        'GD'              => undef,
        'Geo::OSM::Tiles' => undef,
        'Math::Trig'      => undef,
        'XML::Parser'     => undef,
    }, 

    ( ## Add these new keywords supported since 5.005
    $] >= 5.005 ?   (
        ABSTRACT      => 'API to allow plotting of geographical data on a map', 
        AUTHOR        => 'Aki Mimoto <aki-cpan@bako.ca>'
    ) : ()
    ),

    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

);
