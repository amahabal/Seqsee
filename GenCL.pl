# This program reads the file SCodeConfig.txt and writes lib/SCodeConfig.pm


package LaunchInstance;
sub new{  bless {}, shift }

package main;
use Carp;
open IN,  "     SCodeConfig.txt";
open OUT, ">lib/SCodeConfig.pm";

my %Vars;
my $CurrentLauncher;
my $CurrentSetTag;
my $CurrentObject;
my @Objects;

print OUT <<PREAMBLE;
package CodeConfig;
our \%Post;

PREAMBLE

while ($in = <IN>) {
  # print "Processing line: $in";
  chomp $in;
  $in =~ s/#.*$//;
  next if $in =~ /^\s*$/;
  $in =~ s#^\s*##;
  $in =~ s#\s*$##;
  if ($in =~ /^define\s*«(.*?)»\s*(.*)/) {
    my ($var, $val) = ($1, $2);
    $Vars{$var} = $val;
    # print "Variable Definition! '$var' defined to be '$val'\n";
  } elsif ($in =~ /^for\s+(\S+)\s*(.*)/) {
    my ($launcher, $rest) = ($1, $2);
    # print "Launcher now '$launcher'. Rest args: '$rest'\n";
    $CurrentLauncher = $launcher;
    if ($rest) {
      if ($rest =~ /:Bundle«(.*?)»/) {
	$CurrentSetTag = $1;
	# print "CurrentSetTag now $CurrentSetTag\n";
      }
    } else {
      $CurrentSetTag = undef;
    }
  } else {
    my %this_line_stuff;
    while ($in) {
      if ($in =~ s#:(\w+)«(.*?)»\s*##) {
	my ($type, $arg) = ($1, $2);
	# print "\t'$type' is '$arg'";
	my $effective_val;
	if ($arg =~ /^\s*=\s*(.*?)\s*$/) {
	  $varname = $1;
	  $effective_val = $Vars{$varname};
	  unless (defined $effective_val) {
	    confess "$varname not already defined!\n";
	  }
	  # print ", which is just $effective_val";
	} else {
	  $effective_val = $arg;
	}
	# print "\n";
	$this_line_stuff{$type} = $effective_val; 
      }
    }
    # Okay, so I have some stuff here.
    next unless %this_line_stuff;
    if ($this_line_stuff{key}) {
      # Must also have a family here
      if ($CurrentSetTag) {
	die "You have defined a key when a BundleTag was in effect. This will be useless, and is probably an error!. Bundle '$CurrentSetTag' of $CurrentLauncher\n";
      }
      my $key = $this_line_stuff{key};
      my $family = $this_line_stuff{family} || die "Family a must with a key!\n";
      if ($CurrentObject) {
	push(@Objects, $CurrentObject);
      }
      $CurrentObject = new LaunchInstance;
      $CurrentObject->{Launcher} = $CurrentLauncher;
      while (my ($key, $val) = each %this_line_stuff) {
	while ($val =~ s#\$attr\{(.+?)\}#'$'.mangle($1)#e) {
	  $CurrentObject->{NEED_ATT}{$1} = 1;
	}
	if ($key eq "option") {
	  push(@{ $CurrentObject->{options} }, $val);
	  next;
	}
	$CurrentObject->{$key} = $val;
      }
    } elsif ($this_line_stuff{family}) {
      #okay, key must be the same as the family
      my $family = $this_line_stuff{family};
      if ($CurrentObject) {
	push(@Objects, $CurrentObject);
      }
      $CurrentObject = new LaunchInstance;
      $CurrentObject->{Launcher} = $CurrentLauncher;
      if ($CurrentSetTag) {
	$CurrentObject->{TAG} = $CurrentSetTag;
      }
      while (my ($key, $val) = each %this_line_stuff) {
	while ($val =~ s#\$attr\{(.+?)\}#'$'.mangle($1)#e) {
	  $CurrentObject->{NEED_ATT}{$1} = 1;
	}
	if ($key eq "option") {
	  push(@{ $CurrentObject->{options} }, $val);
	  next;
	}
	$CurrentObject->{$key} = $val;
      }
      $CurrentObject->{key} = $family;
    } else {
      confess "Am I seeing attributes without an object?" unless $CurrentObject;
      while (my ($key, $val) = each %this_line_stuff) {
	while ($val =~ s#\$attr\{(.+?)\}#'$'.mangle($1)#e) {
	  $CurrentObject->{NEED_ATT}{$1} = 1;
	}
	if ($key eq "option") {
	  push(@{ $CurrentObject->{options} }, $val);
	  next;
	}
	$CurrentObject->{$key} = $val;
      }
    }
  }
}

if ($CurrentObject) {
  push(@Objects, $CurrentObject);
}
foreach my $o (@Objects) {
#  print "="x30, "\n";
#  foreach (qw{Launcher family key prob urgency}) {
#    print "\t$_\t=>$o->{$_}\n";
# }
  if ($o->{TAG}) {
    my $launcher = $o->{Launcher};
    push(@{ $Deffered{$launcher}{$o->{TAG}} }, $o);
    if ($o->{NEED_ATT}) {
      foreach (keys %{ $o->{NEED_ATT} }) { $Atts{$launcher}{$o->{TAG}}{$_} = 1}
    }
  } else {
    process_single($o);
  }
}

while (my($launcher, $hashref) = each %Deffered) {
  while (my($tag, $arrayref) = each %$hashref) {
    process_multiple($launcher, $tag, @$arrayref);
  }
}

sub process_single{
  my $o = shift;
  #print "="x15, "Single \n";
  #foreach (qw{Launcher family key prob urgency}) {
  #  print "\t$_\t=>$o->{$_}\n";
  #}
  my $launcher = $o->{Launcher};
  my $key      = $o->{key};
  my $family   = $o->{family};
  my $prob     = $o->{prob};
  my $urgency  = $o->{urgency};
  my $need_att = $o->{NEED_ATT};
  if ($need_att) {
    $need_att = "";
    foreach (keys %{$o->{NEED_ATT}}) {
      my $mangled_name = mangle($_);
      $need_att .= "\n    my \$$mangled_name = \$attr{$_} || die 'require option $_ for launching codelet of family $family by $launcher';";
      $need_att .= "\n    delete \$attr{$_};";
    }
  } else {
    $need_att = "";
  }
  my $options  = $o->{options};
  my @options  = (defined $options) ? @$options : ();
  my $option_string = join(",\n\t\t\t\t ", @options);
  $option_string .= "," if $option_string;
  if ($prob eq "1") {
      print OUT <<"STUFF";
\$Post{"$launcher"}{"$key"} =
  sub {
    my \%attr = \@_;$need_att
    my \$how_freq = $prob;
    # No need to toss, always post
    my \$codelet = new SCodelet( "$family",
                               $urgency, $option_string
                              \%attr,
                             );
    SCoderack->add_codelet(\$codelet);
  };

STUFF

  } else {
  print OUT <<"STUFF";
\$Post{"$launcher"}{"$key"} =
  sub {
    my \%attr = \@_;$need_att
    my \$how_freq = $prob;
    if (Utility::toss(\$how_freq)) {
      my \$codelet = new SCodelet( "$family",
                                 $urgency, $option_string
                                 \%attr,
                               );
      SCoderack->add_codelet(\$codelet);
    }
  };

STUFF
    
  }

}

sub process_multiple{
  my $launcher = shift;
  my $tag = shift;
  # print "#"x20, "Multiple $launcher s $tag set\n";
  my $need_att = $Atts{$launcher}{$tag};
  if ($need_att) {
    $need_att = "";
    foreach (keys %{ $Atts{$launcher}{$tag} }) {
      my $mangled_name = mangle($_);
      $need_att .= "\n    my \$$mangled_name = \$attr{$_} || die 'Require option $_';";
      $need_att .= "\n    delete \$attr{$_};\n";
    }
  } else {
    $need_att = "";
  }
  print OUT <<"PRELIM";
\$Post{"$launcher"}{"$tag"} =
  sub {
    my \%attr = \@_;$need_att
    my \$how_freq;
    my \$codelet;
PRELIM
  foreach my $o (@_) {
    my $launcher = $o->{Launcher};
    my $key      = $o->{key};
    my $family   = $o->{family};
    my $prob     = $o->{prob};
    my $urgency  = $o->{urgency};
    my $options  = $o->{options};
    my @options  = (defined $options) ? @$options : ();
    my $option_string = join(",\n\t\t\t\t ", @options);
    $option_string = "\n\t\t\t\t $option_string," if $option_string;    
    if ($prob eq "1") {    
      print OUT <<"STUFF";
    # Always Post next codelet, so no toss
    \$codelet = new SCodelet( "$family",
                            $urgency,$option_string
                            \%attr,
                          );
    SCoderack->add_codelet(\$codelet);
STUFF
    } else {
      print OUT <<"STUFF";
    \$how_freq = $prob;
    if (Utility::toss(\$how_freq)) {
      my \$codelet = new SCodelet( "$family",
                                 $urgency,$option_string
                                 \%attr,
                               );
      SCoderack->add_codelet(\$codelet);
    }
STUFF
    }

  }
  print OUT <<"END";
 };
END
}

print OUT<<POSTAMBLE;

1;
POSTAMBLE

sub mangle{
  my $name = shift;
  return "attr___$name";
}

# #this file generates subroutines that can be called to launch codelets, as a (hopefully far better) substitute for post_codelet_configured.

# # It can generate the following, for example:

# sub Poster::Background__bond_scout {
#   my $codelet = new Codelet( "bond_scout",
# 			     15 * rand(),
# 			   );
#   Coderack->add_codelet($codelet);
# }

# or maybe even:

# $Poster{attribute_slot_evaluator}{attribute_slot_filler} =
#   sub {
#     my %att = @_;
#     my $how_freq = 0.15;
#     if (toss $how_freq) {
#       my $codelet = new Codelet( "attribute_slot_filler",
# 				 15 * $att{strength}
# 			       );
#       Coderack->add_codelet($codelet);
#     }
#   };

# # And then the following code is possible:
# #post_cc "attribute_slot_evaluator", "attribute_slot_filler", strength => 10;

# #and post_cc is just:

# sub post_cc($$%){
#   my $who = shift;
#   my $key = shift;
#   $Poster{$who}{$key}->(@_);
# }

# # That is one key lookup, and two function calls in all, as opposed to the current:

# one call to push_codelet_configured + building defaults hash
# hash lookup, key extraction
# Potentially two function calls for prob and urgency.

# What would the file this stuff is pulled from look like?

# define «low»              0.1
# define «med»              0.15
# define «high»             0.3
# define «high random»      15 * rand()
# define «very high random» 20 * rand()


# for Background
# :family«bond_scout»    :prob«=med» :urgency«=high random»
# :family«bond_scout»    :prob«=low» :urgency«=high random» :key«bond_scout:unhappy»
# :family«group_scout»   :prob«=low» :urgency«=high random»
# :family«group_remake»  :prob«=low» :urgency«=very high random»

# for group_evaluator
# :family«attribute_slot_scout»
#   :prob«=med» :urgency«15 * $attr{strength}»

# for group_extension
# :family«bond_scout»           :prob«=very high» :urgency«5 * $attr{strength}»
# :family«attribute_slot_scout» :prob«=certain»   :urgency«5 * $attr{strength}»

# Maybe I can also have support for groups; In case of Background, for instance, it does not make sense to have so many calls, when we can launch all simultaneously. So I may have:

# for Background :Bundle«all»
# :family«bond_scout»    :prob«=med» :urgency«=high random»
# :family«bond_scout»    :prob«=low» :urgency«=high random» :key«bond_scout:unhappy»
# :family«group_scout»   :prob«=low» :urgency«=high random»
# :family«group_remake»  :prob«=low» :urgency«=very high random»

# And then I would say:

# post_cc_bundle "Background", "all", strength => 10;

# Unless something has $arg{} in it, the generated function will not even construct the corresponding hash. This is so darn simple. This is also configurable, more than it was before, in fact, and a *lot* faster, I imagine.

# What still needs to be figured out is namespaces and such!

