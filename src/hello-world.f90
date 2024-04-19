! Copyright 2024 IBM All Rights Reserved.
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
! http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.

! Simple program that takes a real as an input and outputs the result of an equation
! The idea here is to provide an output metric that could be used as part of a Katib
! experiment. A simple equation is not something Katib is designed for, but we can imagine
! a hyperparameter tuning scenario, where the objective metric has a clean minimum. In this
! example, the SLEEP simulates a long running operation, and y is a mock objective function
! that changes based on the hyperparameter x.
program hello
    integer :: num_args
    character(len=32) :: arg
    real :: x, y
  
    ! For example purposes, if x is not provided, use a value of 0
    num_args = command_argument_count()
    IF (num_args < 1) THEN
       x = 0
    ELSE
      ! Assuming x is a valid real number 
      CALL get_command_argument(1, arg)
      READ(arg, '(f10.0)') x
    END IF
  
    ! In practice, we never have anything we want to tune run so fast that the main 
    ! container ends before the sidecar gets started. So we'll do a sleep here to 
    ! avoid potential problems where the program ends too quickly.
    CALL sleep(5)
  
    y = (x-5)**2 + 1
  
    ! Format the output in the format that Katib expects.
    ! It would be better to put this output in a log file, used only for
    ! logging metrics, but for this simple example stdout is fine.
    PRINT '((a))', "epoch 0:"
    PRINT '((a), (f0.2))',  "y=",  y
  
  end program hello