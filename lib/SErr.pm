# I am perhaps erring on the side of using too many..
use strict;
use Exception::Class (
    'SErr'                     => {},
    'SErr::LTM_LoadFailure'    => { fields => ['what']},
    'SErr::Pos::OutOfRange'    => {},
    'SErr::Pos::UnExpMulti'    => {},
    'SErr::Pos::MultipleNamed' => {},
    'SErr::Att::Missing'       => { fields => ['what'] },
    'SErr::Att::Extra'         => { fields => ['what'] },
    'SErr::EmptyCreate'        => {},

    'SErr::UnderlyingRelnUnapplicable' => {},
    'SErr::ConflictingGroups' => { fields => ['conflicts']},

    'SErr::Code' => {},

    'SErr::ProgOver' => {},

    'SErr::NotOfCat'            => {},
    'SErr::MetonymNotAppicable' => {},

    'SErr::HolesHere' => {},    #thrown by SAnchored constructor

    'SErr::AskUser' => { fields => [qw{already_matched 
                                       next_elements
                                       object
                                       from_position
                                       direction
                                   }] },

    'SErr::FinishedTest' => { fields => [qw( got_it)] },
    'SErr::FinishedTestBlemished' => {},
    'SErr::NotClairvoyant' => {},

    'SErr::CouldNotCreateExtendedGroup' => {},
);
SErr::HolesHere->Trace(1);
1;

