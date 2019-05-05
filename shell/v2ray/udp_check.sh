#!/bin/bash

nc -uz -w 1 $1 $2 | grep succeeded >/dev/null

exit $?
