package SUtility;

sub toss($) {
  ( rand() <= shift ) ? 1 : 0;
}

1;
