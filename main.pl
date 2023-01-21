use strict;
use warnings;

use FindBin::libs;
#use Log::Log4perl qw(:easy);

use Point;
use Points;
use Segment;


# Unit tests
my $p1=Point->new(x=>10.5,y=>5.33);
print("p1:".$p1->toString());
my $p2=Point->CreateFromString("2.5 3.33");
print("p2:".$p2->toString());


my $s2=Points->CreateFromString(q{2
1.1 1.12
3.3 3.45
});
print("s2:".$s2->toString());


my @points=[$p1,$p2];
my $s1=Segment->new(points=>[$p1,$p2]);
print("s1:".$s1->toString());

