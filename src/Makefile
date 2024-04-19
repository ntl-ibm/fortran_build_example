# Copyright 2024 IBM All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://aoterodelaroza.github.io/devnotes/modern-fortran-makefiles/
.SUFFIXES:

FC:=gfortran -c
LINKER:=gfortran
BUILDDIR := .
SOURCEDIR := .

SOURCES := $(shell find $(SOURCEDIR) -name '*.f90')
OBJECTS := $(addprefix $(BUILDDIR)/,$(SOURCES:%.f90=%.o))

# The S2I builder that is used assumes that the app is named
# "Application". We could change this by providing out own 'run'
# script that overrides the default from the builder.
APPLICATION := Application

$(info $$SOURCES is [${SOURCES}])
$(info $$OBJECTS is [${OBJECTS}])

%.o %.mod %.smod: %.f90
		$(FC) -o $*.o $<

main: $(OBJECTS) $(APPLICATION)

$(APPLICATION): $(OBJECTS)
		$(LINKER) $(OBJECTS) -o $(APPLICATION)

.PHONY:  
clean:
		-rm -f *.o *.mod *.smod main $(APPLICATION)