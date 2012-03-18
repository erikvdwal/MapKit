@implementation MKAnnotation : CPObject
{
	CPString title @accessors();
	CPString subtitle @accessors();
	CLLocationCoordinate2D coordinate @accessors(readonly);	
	
	CPString icon @accessors();
	
}

- (id)init
{
	if(self = [super init])
	{
		coordinate = CLLocationCoordinate2DMake(0.0,0.0);
		title = @"";
	}
	
	return self;
}


- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	coordinate = aCoordinate;
}


@end