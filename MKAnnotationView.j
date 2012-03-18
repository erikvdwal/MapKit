@implementation MKAnnotationView : CPView
{
	BOOL enabled @accessors(getter=isEnabled);	
	BOOL highlighted @accessors(getter=isHighlighted);
	CPImage image @accessors();
	CPView leftCalloutAccessoryView @accessors();
	CPString reuseIdentifier @accessors(readonly);
	CPView rightCalloutAccessoryView @accessors();
	BOOL selected @accessors(getter=isSelected);
	MKAnnotation annotation @accessors();
	CPPoint calloutOffset @accessors();
	BOOL canShowCallout @accessors();
	CPPoint centerOffset @accessors();
	BOOL draggable @accessors(getter=isDraggable);
	
	//TODO : Dragstate
}

- (id)initWithAnnotation:(MKAnnotation)aAnnotation reuseIdentifer:(CPString)aIdentfier
{
	if(self = [super init])
	{
		self.annotation = aAnnotation;
	}
	
	return self;
}

- (void)prepareForReuse
{
	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	
}

/*
- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated
{
	
}*/



@end