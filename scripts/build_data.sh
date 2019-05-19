#!/bin/bash

set -e

echo "Starting Valhalla data build pipeline..."

COMMAND_ROOT=$PWD

cd $VALHALLA_BASE_DATA_DIR

if [ -d "$VALHALLA_DATA_VERSION" ]; then
    echo "Data dir with this version already exists! Check tasks..."  
else
    echo "Creating data dir..."
    mkdir $VALHALLA_DATA_VERSION
    touch $VALHALLA_DATA_VERSION/tasks_log
fi

cd $VALHALLA_DATA_VERSION

if [ ! -z $(grep "download_pbf_done" "tasks_log") ]; then
    echo "PBF is already downloaded."
else
    echo "Downloading iran PBF data..."
    wget -O iran-latest.osm.pbf http://download.geofabrik.de/asia/iran-latest.osm.pbf
    echo "download_pbf_done" >> tasks_log
fi

if [ ! -z $(grep "generate_config_done" "tasks_log") ]; then
    echo "Config is already generated."
else
    echo "Generating config file..."    
    rm -rf valhalla_tiles
    mkdir valhalla_tiles
    valhalla_build_config --mjolnir-tile-dir ${PWD}/valhalla_tiles --mjolnir-tile-extract ${PWD}/valhalla_tiles.tar --mjolnir-timezone ${PWD}/valhalla_tiles/timezones.sqlite --mjolnir-admin ${PWD}/valhalla_tiles/admins.sqlite > valhalla.json
    echo "generate_config_done" >> tasks_log
fi

if [ ! -z $(grep "build_admins_done" "tasks_log") ]; then
    echo "Admins are already built."
else
    echo "Building admins..."
    valhalla_build_admins --config valhalla.json
    echo "build_admins_done" >> tasks_log
fi

if [ ! -z $(grep "build_timezones_done" "tasks_log") ]; then
    echo "Timezones are already built."
else
    echo "Building timezones..."
    cp $COMMAND_ROOT/alias_* ./
    rm -f timezones-with-oceans.shapefile.zip
    valhalla_build_timezones valhalla.json
    echo "build_timezones_done" >> tasks_log
fi

if [ ! -z $(grep "build_tiles_done" "tasks_log") ]; then
    echo "Tiles are already built."
else
    echo "Building tiles..."
    valhalla_build_tiles -c valhalla.json iran-latest.osm.pbf
    echo "build_tiles_done" >> tasks_log
fi

if [ ! -z $(grep "build_tar_done" "tasks_log") ]; then
    echo "Tar is already built."
else
    echo "Building tar..."
    set +e
    find valhalla_tiles | sort -n | tar cf valhalla_tiles.tar --warning=no-file-changed --no-recursion -T -
    exitcode=$?
    if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
        exit $exitcode
    fi
    set -e
    echo "build_tar_done" >> tasks_log
fi

echo "Data build with version $VALHALLA_DATA_VERSION is done!"
exit 0
