#!/usr/bin/env bash

bundle > /dev/null && ./lib/socrata_crime_layer_generator.rb "$@"