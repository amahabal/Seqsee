class SChooser{

  our $NULL = SChooser::NULL.new;
  our $By_strength = SChooser::ByName.new("strength");
 
  method new($what){
    given ($what) {
      when (CODE)     { return SChooser::BySub.new($what) }
      when (SChooser) { return $what }
      when (false)    { return $NULL}
      default         { return SChooser::ByName.new($what) }
    }
  }

}

class SChooser::NULL   {...}
class SChooser::ByName {...}
class SChooser::BySub  {...}
class SChooser::ByWt   {...}
