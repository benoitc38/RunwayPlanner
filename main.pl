use strict;
use warnings;

use FindBin::libs;
#use Log::Log4perl qw(:easy);

use Point;
use Points;
use Segment;


# Unit tests
my $p1=Point->new(x=>5,y=>13);
print("p1:".$p1->toString());
my $p2=Point->CreateFromString("8 10");
print("p2:".$p2->toString());

my $p3=Point->CreateFromString("5 10");
print("p3:".$p3->toString());
my $p4=Point->new(x=>6,y=>10);
print("p4:".$p4->toString());


my $island=Points->CreateFromString(q{2
1.1 1.12
3.3 3.45
});
print("island:".$island->toString());


my @points=[$p1,$p2];
my $s1=Segment->new(points=>[$p1,$p2]);
print("s1:".$s1->toString());

my $s2=Segment->new(points=>[$p3,$p4]);
print("s2:".$s2->toString());


my $iPoint=$s1->computeLineIntersection($s2);

print("intersection:".$iPoint->toString());

