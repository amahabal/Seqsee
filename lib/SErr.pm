# I am perhaps erring on the side of using too many..
use Exception::Class 
  (
   'SErr::Pos::OutOfRange'       => {},
   'SErr::Pos::UnExpMulti'       => {},
   'SErr::Pos::MultipleNamed'    => {},
   'SErr::Att::Missing'          => {fields => ['what']},
   'SErr::Att::Extra'            => {fields => ['what']},

   'SErr::Code'                  => {},
   'SErr::Code::UnknownFamily'   => { isa => 'SErr::Code' },
   'SErr::Code::MalFormed'       => { isa => 'SErr::Code' },

);
1;

