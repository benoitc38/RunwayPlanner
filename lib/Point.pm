=head1 DESCRIPTION
Point representation
=cut

package Point;
use Modern::Perl;
use experimental 'signatures';
use Moose;

has x => (is=>'rw', isa=>'Num');
has y => (is=>'rw', isa=>'Num');

# 
sub CreateFromString{
    my $cls=shift;
    my @coordinates=split(' ',shift);
    if (scalar @coordinates>=2){
        return Point->new(x=>$coordinates[0],y=>$coordinates[1]);
    }
    return undef;
}

# TO DO if time for SVG rendering since only positive coordinate can be rendered?
sub translate(){

}
# when point is draw as a standalone segment
# input: index of the point in the segment
# example: x1="0" y1="80" or x2="100" y2="20"
sub toSVGSegmentString($self, $ind){
    return "x$ind=$self->{x} y$ind=$self->{y}";
}

sub toSVGString($self){
    return "${\$self->{x}},${\$self->{y}}";
}

sub toString{
    my $self=shift;
    my $st="";
    $st.="x:$self->x";  
    $st.="y:$self->{y}";
    $st="($self->{x},$self->{y})";
    return $st;
}
1