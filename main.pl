=head1 DESCRIPTION
Note: The very first line of the csv file has been removed since info is redundant.
=cut
use Modern::Perl;


use FindBin::libs;
#use Log::Log4perl qw(:easy);

use Point;
use Points;
use Segment;


# Unit tests
my $p1=Point->new(x=>5,y=>13);
print("unit test p1:".$p1->toString());
my $p2=Point->CreateFromString("8 10");
print("unit test p2:".$p2->toString());

my $p3=Point->CreateFromString("5 10");
print("unit test p3:".$p3->toString());
my $p4=Point->new(x=>6,y=>11);
print("unit test p4:".$p4->toString());


my $island=Points->CreateFromString(q{2
1 1
3 4
});
$island->addFromLine("1 2");
print("unitTestIsland1:".$island->toString());
$island->name("unitTestIsland1");
$island->toSVGFile();

$island=Points->new(points=>[], candidateSegments=>[], name=>"unitTestIsland2");
$island->addFromLine("4 5");
print("unitTestIsland2:".$island->toString());
$island->toSVGFile();

my $island1=Points->CreateFromFile("island1.txt");
$island1->initialize();
print("island1:".$island1->toString());


#island 1 (first file)
my $v1=$island1->getVertexByIndex(0);

# Vertex unit tests
# first vertex
print("\nfirst vertex:".$v1->toString());
print("\nfirst next vertex:".$v1->getNext()->toString());
print("\nfirst previous vertex:".$v1->getPrevious()->toString());
print("\n previous edge:".$v1->getPreviousEdge()->toString());
print("\n next edge:".$v1->getNextEdge()->toString());
print("\n previous edge angle:".$v1->getPreviousEdgeAngle());
print("\n next edge angle:".$v1->getNextEdgeAngle());

# last vertex
my $v6=$island1->getVertexByIndex(6);
print("\nlast vertex next vertex:".$v6->getNext()->toString());
print("\nlast vertex next edge:".$v6->getNextEdge()->toString());
print("\n previous edge angle:".$v6->getPreviousEdgeAngle());
print("\n next edge angle:".$v6->getNextEdgeAngle());

$island1->buildEdges();
$island1->buildCandidateSegments(0);
$island1->buildLongestSegments();
print("island1:".$island1->toString());
$island1->toSVGFile();

#island 2 (second file)
my $island2=Points->CreateFromFile("island2.txt");
#print("island2:".$island2->toString());
$island2->buildEdges();
$island2->buildCandidateSegments(0);
$island2->buildLongestSegments();
print("island2:".$island2->toString());
$island2->toSVGFile();

=pod
my @points=[$p1,$p2];
my $s1=Segment->new(points=>[$p1,$p2], name=>'s1');
print("s1:".$s1->toString()." length:".$s1->getLength());
$s1->toSVGFile();

my $s2=Segment->new(points=>[$p3,$p4]);
print("s2:".$s2->toString());


my $iPoint=$s1->computeLineIntersection($s2);

print("intersection:".$iPoint->toString());
=cut
