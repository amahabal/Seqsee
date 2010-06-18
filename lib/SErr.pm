# I am perhaps erring on the side of using too many..
use strict;
use Exception::Class (
  #Generic error
  'SErr'                     => {},

  # Long-term Memory loading issues; caught by SLTM::Load. 
  'SErr::LTM_LoadFailure'    => { fields => ['what'] },

  'SErr::ProgOver' => {},

  # Thrown, never caught
  'SErr::NotOfCat'            => {},

  'SErr::MetonymNotAppicable' => {},

  # Never thrown?
  'SErr::HolesHere' => {},    #thrown by SAnchored constructor

  'SErr::AskUser' => {
    fields => [
      qw{already_matched
      next_elements
      object
      from_position
      direction
      }
    ]
  },

  'SErr::FinishedTest'          => { fields => [qw( got_it)] },
  'SErr::FinishedTestBlemished' => {},
  'SErr::NotClairvoyant'        => {},

  'SErr::CouldNotCreateExtendedGroup' => {},
);
SErr::HolesHere->Trace(1);
1;

