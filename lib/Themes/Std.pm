package Themes::Std;
use Memoize;
use SColor;
*HSV = \&SColor::HSV2Color;

use Compile::Style;
[style] Element
[font]  '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'
[anchor]'center'
[fill] HSV(100,20,20)

no Compile::Style;

use Compile::Style;
[style] Relation
[arrow] 'last'
[width] 1
[params] $strength
[fill] HSV(180,30+0.3*$strength,10+80*$strength)

no Compile::Style;
