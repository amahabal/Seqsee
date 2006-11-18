# I am perhaps erring on the side of using too many..
use strict;
use Exception::Class (
    'SErr'                     => {},
    'SErr::Pos::OutOfRange'    => {},
    'SErr::Pos::UnExpMulti'    => {},
    'SErr::Pos::MultipleNamed' => {},
    'SErr::Att::Missing'       => { fields => ['what'] },
    'SErr::Att::Extra'         => { fields => ['what'] },

    'SErr::ConflictingGroups' => { fields => ['conflicts']},

    'SErr::Code' => {},

    'SErr::ProgOver' => {},

    'SErr::NotOfCat'            => {},
    'SErr::MetonymNotAppicable' => {},

    'SErr::NeedMoreData' => { fields => ['payload'] },
    'SErr::ContinueWith' => { fields => ['payload'] },

    'SErr::HolesHere' => {},    #thrown by SAnchored constructor

    'SErr::AskUser' => { fields => [qw{already_matched next_elements}] },

    'SErr::FinishedTest' => { fields => [qw( got_it)] },
    'SErr::FinishedTestBlemished' => {},
    'SErr::NotClairvoyant' => {},
);
1;

