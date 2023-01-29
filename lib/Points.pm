=head1 NAME
Points/Point set representing Polygon but also Segment/Edge, could be derived into Polygon at some point
=head1 DESCRIPTION
Represents a point set and therefore maybe used to represent a Polygon
When representing a Polygon, point order is counter clockwise by convention
Some methods are only relevant for Polygon so you may want to derive Polygon from Points at some point;-)
=cut

package Points;
use Modern::Perl;
use experimental 'signatures';
use Moose;

use Point;
use Vertex;
use constant CSV_EXT => '.csv';
use constant TXT_EXT => '.txt';
use constant SVG_EXT => '.svg';


has points => (
                    is=>'rw', 
                    isa=>'ArrayRef[Vertex]',
                    traits  => ['Array'],
                    handles =>{
                       all_points => 'elements',
                       count_points  => 'count',
                       add_point     => 'push',
                       find_point   =>'first' # need an argument?
                    }
                );

# edges (used for invalid runway segment identification)
has edges =>( 
                            is=>'ro',
                            isa=>'ArrayRef[Segment]',
                            traits => ['Array'],
                            handles =>{
                                all_edges => 'elements',
                                count_edges => 'count',
                                add_perimeterSegment => 'push'
                            },
                            default=>sub{[]}
                          );

# runway candidate segments
has candidateSegments =>( 
                            is=>'ro',
                            isa=>'ArrayRef[Segment]',
                            traits => ['Array'],
                            handles =>{
                                all_candidateSegments => 'elements',
                                count_candidateSegments => 'count',
                                add_candidateSegment => 'push'
                            }
                          );
# where valid longest segments are stored (array since multiple equal-length possible)
has longestSegments => (
                            is=>'ro',
                            isa=>'ArrayRef[Segment]',
                            traits => ['Array'],
                            handles =>{
                                all_longestSegments => 'elements',
                                count_longestSegments => 'count',
                                add_longestSegment => 'push'
                            },
                            default=>sub{[]}
                         );
# optional name typically the one from the CSV
has name =>( 
            is=>'rw',
            isa=>'Maybe[Str]',
            default=>sub {undef}
            );

# create an instance from a multi line string with first line containing line#
# following lines containing the point coordinates
# static class builder method
sub CreateFromString{
    my $cls=shift;
    my $st=shift;
    my @lines=split("\n",$st);
    my $line_count=@lines;
    # validation: check first line has the right count
    if (!$line_count){
        print("Empty input file!"); # TBI error log
        return undef;
    }
    my $first_line_count=shift(@lines);
    if ($first_line_count!=$line_count-1){
        print("Inconsistent first line $first_line_count! Expecting ($line_count-1) instead)");
        return undef
    }
    my @points=map(Vertex->CreateFromString($_), @lines);
    return Points->new(points=>\@points, candidateSegments=>[]);
}

sub CreateFromFile{
    my $cls=shift;
    my $file_name=shift;
    open my $input, '<', $file_name or die "can't open $file_name: $!";
    $file_name =~ s/\.txt//; # get the CSV file name as the point set name (e.g: polygon name)
    my $points=Points->new(points=>[], candidateSegments=>[], name=>$file_name);
    while (<$input>) {
        chomp;
        $points->addFromLine($_);
    }
    close $input or die "can't close $file_name $!";
    return $points;
}

# strange behavior: is executed but not properly initialized? 
sub BUILD {
    my $self = shift;
    my @vertices=$self->all_points();

    if (@vertices>=3){ # don't process Segment as Vertex yet (future?)
        my $ind=0;
        foreach my $v ($self->all_points()){
            $v->container($self);
            $v->index($ind);
            $ind++;
        }
    }
    #$self->initialize(); # doesn't help neither
}

# to workaround BUILD hook issue?!
# also build the edges in the same counter-clockwise order as vertices
sub initialize($self){
    my @vertices=$self->all_points();
    if ($self->count_points()>=3){ # segments should not be considered as containers
        for (my $ind=0;$ind<$self->count_points();$ind++){
            $vertices[$ind]->container($self);
            $vertices[$ind]->index($ind);
        }
        $self->buildEdges();
    }
}

# returns Vertex from index or undef
# input: ind index starting at 0
sub getVertexByIndex($self, $ind){
    my @points=$self->all_points();
    if ($ind<$self->count_points()){
        return $points[$ind];
    }else{
        return undef;
    }
}

# returns Vertex from index or undef
# precondition: edge have been built but as part of initialization
# precondition: $ind is valid? or let Perl cope with negative indexes?
# input: ind index starting at 0
sub getEdgeByIndex($self, $ind){
    my @edges=$self->all_edges();
    if ($ind<$self->count_edges()){
        return $edges[$ind];
    }else{
        return undef;
    }
}

# input: line as a string
sub addFromLine{
    my $self=shift;
    my $line=shift;
    my $point=Vertex->CreateFromString($line);
    if ($point){
        $self->add_point($point);
    }
}

# builds it any candidate segment array starting from the index ind
#
# returns an array of Segments
sub buildCandidateSegments{
    my $self=shift;
    my $ind=shift;
    my $point_count=$self->count_points();
    my @points=$self->all_points();
    if ($ind>=$point_count-1){
        return;
    }
    for (my $i=$ind+1;$i<$point_count;$i++){
        $self->add_candidateSegment(Segment->new(points=>[$points[$ind],$points[$i]]));
    }
    $self->buildCandidateSegments($ind+1); # recurse
}

# to sort in reverse length order
sub compareLength{
    return $b->isLongerThan($a);
}

# build an array ref of longest and valid Segments if needed i.e. cache is empty cache result
# relies on ordered segment candidates
sub buildValidLongestSegments{
    my $self=shift;
    if ($self->count_longestSegments()>0){
        return;} # job already done
    my @candidateSegments=$self->all_candidateSegments();
    # sort them by length in descending order
    my @sortedCandidateSegments=sort compareLength @candidateSegments;
    # iterate thru the list until a valid candidate is found
    my $topLength;
   
    foreach my $candidateSegment (@sortedCandidateSegments){
        if (!$self->isValid($candidateSegment)){  # optimize: check after equality?
            next;
        }
        if (!defined($topLength)){ # store top length in case of equality
            $topLength=$candidateSegment->getLength();
        }
        if ($topLength-$candidateSegment->getLength()<=10**-6){
            $self->add_longestSegment($candidateSegment);
        }else{
            last;
        }
    }
}

# Runway should be on-shore

# build edges
# only polygons > 3 (at least a triangle) make sense
sub buildEdges($self){
    my $point_count=$self->count_points();
    if ($point_count<3){
        return;
    }
    my @points=$self->all_points();
    if ($self->count_edges()>0){
        return; # computation done once
    }
    for (my $ind = 0; $ind < $point_count-1; $ind++) {
        $self->add_perimeterSegment(Segment->new(points=>[$points[$ind],$points[$ind+1]]));
    }
    # add last one by looping back to first point
    $self->add_perimeterSegment(Segment->new(points=>[$points[$point_count-1],$points[0]]));

}

# checks whether the $s segment intersects any of the polygon Edge interior 
# Note: adjacent intersection returns 0
# returns 1 or 0
sub intersectsAnyEdgeInterior($self, $s){
    foreach my $e ($self->all_edges()){
        if ($s->intersectsSegmentInterior($e)){
            return 1;
        }
    }
    return 0;
}

# ensure the candidate segment is fully onshore:
#     -should not intersect any edge interior (other than at its start and end)
#     -should not start directly off-shore: ensure that starting angle is within the containing edge angles
sub isValid($self, $candidateSegment){
    if ($self->intersectsAnyEdgeInterior($candidateSegment)){
        return 0;
    }
    if (!$candidateSegment->directsOnShore()){
        return 0;
    }
    return 1;
}

sub toSVGFile($self){
    my $name=$self->name || "noName";
    my $file_path=$name.SVG_EXT;
    if (open FILE, '>:utf8', $file_path) {
        print FILE $self->toSVGString();
        close FILE;
    }   
}

# SVG format examples

# <polygon points="0,100 50,25 50,75 100,0" />
sub toSVGString($self){
   my $st='<svg viewBox="-20 -20 200 100" xmlns="http://www.w3.org/2000/svg">';
   # draw the perimeter shape
   $st.=$self->toSVGHTMLTagString(); 
   # draw the longest segment
   if ($self->count_longestSegments()>0){
        $st.=join(',',map($_->toSVGHTMLTagString(), $self->all_longestSegments()));
   }
   $st.="</svg>";
   return $st;
}

# draw the perimeter shape
sub toSVGHTMLTagString($self){
    my $st="";
    if ($self->count_points()>2){
        $st.='<polygon points="';
        $st.=join(" ",map($_->toSVGString(), $self->all_points()));
        $st.='" fill="none" stroke="black" />';
    }
    return $st;
}

sub toString{
    my $self=shift;
    my $st="";
    #my $count=$self->count_points;
    $st.='['.join(',',map($_->toString(), $self->all_points())).']';
    if ($self->count_edges()>0){
        $st.="\nedges#:${\$self->count_edges()}";
        $st.="\nedges:[".join(',',map($_->toString(), $self->all_edges())).']';
    }
    if ($self->all_candidateSegments()){
        $st.="\ncandidate segments:[".join(',',map($_->toString(), $self->all_candidateSegments())).']';
    }
    if ($self->count_longestSegments()>0){
        $st.="\nvalid longest segments#:${\$self->count_longestSegments()}";
        $st.="\nvalid longest segments:[".join(',',map($_->toString(), $self->all_longestSegments())).']';
    }
    
    return $st;
}

no Moose;
__PACKAGE__->meta->make_immutable;