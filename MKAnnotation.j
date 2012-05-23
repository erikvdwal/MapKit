MKAnnotationAnimationTypeNone   = null;
MKAnnotationAnimationTypeBounce = 1;
MKAnnotationAnimationTypeDrop   = 2;

@implementation MKAnnotation : CPObject
{
	BOOL canShowCallout @accessors();
	CPString title @accessors();
	CPString subtitle @accessors();
	CLLocationCoordinate2D coordinate @accessors(readonly);
	MKAnnotationAnimationType animationType @accessors();

	CPString icon @accessors();
}

- (id)init
{
	if(self = [super init])
	{
		coordinate = CLLocationCoordinate2DMake(0.0,0.0);
		title = @"";
		animationType = MKAnnotationAnimationTypeNone;
	}

	return self;
}

- (void)setAnimatesDrop:(BOOL)animatesDrop
{
	if (animatesDrop)
	{
		[self setAnimationType:MKAnnotationAnimationTypeDrop];
	}
	else
	{
		[self setAnimationType:MKAnnotationAnimationTypeNone];
	}
}

- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	coordinate = aCoordinate;
}


@end
