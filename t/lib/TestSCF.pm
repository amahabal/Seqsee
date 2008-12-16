use Compile::SCF;
[package] SCF::family_foo
[param] a
<run>
    return 97 + $a;
</run>
no Compile::SCF;

use Compile::SCF;
[package] SCF::test
[param] foo
<run>
    return $foo;
</run>
no Compile::SCF;


1;
