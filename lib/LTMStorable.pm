package LTMStorable;
use Moose::Role;

requires 'get_pure';
requires 'get_memory_dependencies';
requires 'serialize';
requires 'deserialize';

1;
