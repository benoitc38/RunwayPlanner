=head1 NAME
Points/Point set
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
use constant CSV_EXT => '.csv';
use constant TXT_EXT => '.txt';
use constant SVG_EXT => '.svg';


has 'points' => (
                    is=>'rw', 
                    isa=>'ArrayRef[Point]',
                    traits  => ['Array'],
                    handles =>{
                       all_points => 'elements',
                       count_points  => 'count',
                       add_point     => 'push'
                    }
                );
has 'candidateSegments' =>( 
                            is=>'ro',
                            isa=>'ArrayRef[Segment]',
                            traits => ['Array'],
                            handles =>{
                                all_candidateSegments => 'elements',
                                count_candidateSegments => 'count',
                                add_candidateSegment => 'push'
                            }
                          );

has 'longestSegments' => (
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
    my @points=map(Point->CreateFromString($_), @lines);
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

# input: line as a string
sub addFromLine{
    my $self=shift;
    my $line=shift;
    my $point=Point->CreateFromString($line);
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

# build an array ref of longest Segments if needed i.e. cache is empty
# cache result
sub buildLongestSegments{
    my $self=shift;
    if ($self->count_longestSegments()>0){
        return;} # job already done
    my @candidateSegments=$self->all_candidateSegments();
    # sort them by length in descending order
    my @sortedCandidateSegments=sort compareLength @candidateSegments;
    my $topLength;
    if (@sortedCandidateSegments>0){
        $topLength=$sortedCandidateSegments[0]->getLength();
    }
    foreach my $candidateSegment (@sortedCandidateSegments){
        if ($topLength-$candidateSegment->getLength()<=10**-6){
            $self->add_longestSegment($candidateSegment);
        }else{
            last;
        }
    }
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
   my $st='<svg viewBox="-200 -200 200 100" xmlns="http://www.w3.org/2000/svg">';
   $st.=$self->toSVGHTMLTagString(); 
   $st.="</svg>";
   return $st;
}

sub toSVGHTMLTagString($self){
    my $st="";
    if ($self->count_points>2){
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
    if ($self->all_candidateSegments()){
        $st.="\ncandidate segments:[".join(',',map($_->toString(), $self->all_candidateSegments())).']';
    }
    if ($self->count_longestSegments()>0){
        $st.="\nlongest segments#:${\$self->count_longestSegments()}";
        # TO DO add them also
    }
    return $st;
}

no Moose;
1
