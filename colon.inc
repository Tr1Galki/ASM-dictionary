%define LIST_POINTER 0

%macro colon 2
%2: 
dq LIST_POINTER
db %1, 0
%define LIST_POINTER %2 

%endmacro