use strict;
use warnings;

use FindBin::libs;

use Point;
use Points;

#$p1=Point->new;
my $p1=Point->new(x=>10.5,y=>5.33);
print($p1->toString());
my $island=Points->new(points=>[$p1]);
$island->toString();

