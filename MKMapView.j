// MKMapView.j
// MapKit
//
// Created by Francisco Tolmasky.
// Copyright (c) 2010 280 North, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

@import <AppKit/CPView.j>

@import "MKGeometry.j"
@import "MKTypes.j"


@implementation MKMapView : CPView
{
    CLLocationCoordinate2D  m_centerCoordinate;
    int                     m_zoomLevel;
    MKMapType               m_mapType;

    BOOL                    m_scrollWheelZoomEnabled;

    // Tracking
    BOOL                    m_previousTrackingLocation;

    // Google Maps v3 DOM Support
   	DOMElement              m_DOMMapElement;
	Object                  m_map;

    @outlet                 id delegate @accessors;
    BOOL                    delegateDidSendFinishLoading;
    CPArray                 annotations @accessors(readonly);
    CPDictionary            markerDictionary;
    MapOptions              m_options @accessors(property=options);
}

+ (void)initialize
{
	[self exposeBinding:CPValueBinding];
}

+ (Class)_binderClassForBinding:(CPString)theBinding
{
    if (theBinding === CPValueBinding)
        return [_CPValueBinder class];

    return [super _binderClassForBinding:theBinding];
}

+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLatitude
{
    return [CPSet setWithObjects:@"centerCoordinate"];
}

+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLongitude
{
    return [CPSet setWithObjects:@"centerCoordinate"];
}

+ (int)_mapTypeIdForMapType:(MKMapType)aMapType
{
    return  [
                google.maps.MapTypeId.ROADMAP,
                google.maps.MapTypeId.HYBRID,
                google.maps.MapTypeId.SATELLITE,
                google.maps.MapTypeId.TERRAIN
            ][aMapType];
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame centerCoordinate:nil];
}

- (id)initWithFrame:(CGRect)aFrame centerCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setCenterCoordinate:aCoordinate || new CLLocationCoordinate2D(52, -1)];
        [self setZoomLevel:6];
        [self setMapType:MKMapTypeStandard];
        [self setScrollWheelZoomEnabled:YES];

        [self _init];
        [self _buildDOM];
    }

    return self;
}

- (void)_init
{
    [self setBackgroundColor:[CPColor colorWithRed:229.0 / 255.0 green:227.0 / 255.0 blue:223.0 / 255.0 alpha:1.0]];

    annotations = [CPArray array];
    markerDictionary = [[CPDictionary alloc] init];
    delegateDidSendFinishLoading = NO;
    m_options = [[MapOptions alloc] init];
}

- (void)_buildDOM
{
    performWhenGoogleMapsScriptLoaded(function()
    {
        m_DOMMapElement = document.createElement("div");
        m_DOMMapElement.id = "MKMapView" + [self UID];

        var style = m_DOMMapElement.style,
            bounds = [self bounds],
            width = CGRectGetWidth(bounds),
            height = CGRectGetHeight(bounds);

        style.overflow = "hidden";
        style.position = "absolute";
        style.visibility = "visible";
        style.zIndex = 0;
        style.left = -width + "px";
        style.top = -height + "px";
        style.width = width + "px";
        style.height = height + "px";

        // Google Maps can't figure out the size of the div if it's not in the DOM tree,
        // so we have to temporarily place it somewhere on the screen to appropriately size it.
        document.body.appendChild(m_DOMMapElement);

        m_map = new google.maps.Map(m_DOMMapElement,
        {
            center:LatLngFromCLLocationCoordinate2D(m_centerCoordinate),
            zoom:m_zoomLevel,
            mapTypeId:[[self class] _mapTypeIdForMapType:m_mapType],
            scrollwheel:m_scrollWheelZoomEnabled
        });

        google.maps.event.trigger(m_map, "resize");

        style.left = "0px";
        style.top = "0px";

        // REMOVE this or you will get WRONG_DOCUMENT_ERRORS (4)!
        document.body.removeChild(m_DOMMapElement);

        _DOMElement.appendChild(m_DOMMapElement);

        [self _sendDidFinishLoadingNotificationIfNeeded];
        [m_options setMapObject:m_map];

/*
        google.maps.Event.addListener(m_map, "zoomend", function(oldZoomLevel, newZoomLevel)
        {
            [self setZoomLevel:newZoomLevel];

//            [[CPRunLoop currentRunLoop] limitDataForMode:CPDefaultRunLoopMode];
        });
*/
    });
}

- (void)awakeFromCib
{
    // Try to send the delegate message now if the map loaded before the delegate was decoded.
    [self _sendDidFinishLoadingNotificationIfNeeded];
}

- (void)_sendDidFinishLoadingNotificationIfNeeded
{
    if (m_map && !delegateDidSendFinishLoading && delegate && [delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
    {
        [delegate mapViewDidFinishLoadingMap:self];
        delegateDidSendFinishLoading = YES;
    }
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    var bounds = [self bounds];

    if (m_DOMMapElement)
    {
        var style = m_DOMMapElement.style;

        style.width = CGRectGetWidth(bounds) + "px";
        style.height = CGRectGetHeight(bounds) + "px";

        google.maps.event.trigger(m_map, "resize");
    }
}

- (Object)namespace
{
    return m_map;
}

- (MKCoordinateRegion)region
{
    if (m_map)
        return MKCoordinateRegionFromLatLngBounds(m_map.getBounds());

    return nil;
}

- (void)setRegion:(MKCoordinateRegion)aRegion
{
    m_region = aRegion;

    if (m_map)
        m_map.fitBounds(LatLngBoundsFromMKCoordinateRegion(aRegion));
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    m_centerCoordinate = aCoordinate;

    if (m_map)
        m_map.setCenter(LatLngFromCLLocationCoordinate2D(aCoordinate));
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return m_centerCoordinate;
}

- (void)setCenterCoordinateLatitude:(float)aLatitude
{
    [self setCenterCoordinate:new CLLocationCoordinate2D(aLatitude, [self centerCoordinateLongitude])];
}

- (float)centerCoordinateLatitude
{
    return [self centerCoordinate].latitude;
}

- (void)setCenterCoordinateLongitude:(float)aLongitude
{
    [self setCenterCoordinate:new CLLocationCoordinate2D([self centerCoordinateLatitude], aLongitude)];
}

- (float)centerCoordinateLongitude
{
    return [self centerCoordinate].longitude;
}

- (void)setZoomLevel:(float)aZoomLevel
{
    m_zoomLevel = +aZoomLevel || 0;

    if (m_map)
        m_map.setZoom(m_zoomLevel);
}

- (int)zoomLevel
{
    return m_zoomLevel;
}

- (void)setMapType:(MKMapType)aMapType
{
    m_mapType = aMapType;

    if (m_mapType)
        m_map.setMapTypeId([[self class] _mapTypeIdForMapType:m_mapType]);
}

- (MKMapType)mapType
{
    return m_mapType;
}

- (void)setScrollWheelZoomEnabled:(BOOL)shouldBeEnabled
{
    m_scrollWheelZoomEnabled = shouldBeEnabled;

    if (m_map)
        m_map.setScrollWheelZoomEnabled(m_scrollWheelZoomEnabled);
}

- (BOOL)scrollWheelZoomEnabled
{
    return m_scrollWheelZoomEnabled;
}

- (void)setOptions:(CPDictionary)opts
{
    [m_options _setOptionsFromDictionary:opts];
}

- (void)addAnnotation:(MKAnnotation)annotation
{
	[self addAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)addAnnotations:(CPArray)aAnnotationArray
{
	var annotationsCount = [aAnnotationArray count];

	for (var i = 0; i < annotationsCount; i++)
	{
		var annotation = aAnnotationArray[i];

		var marker = null;

		if ([markerDictionary valueForKey:[annotation UID]])
		{
			marker = [markerDictionary valueForKey:[annotation UID]];
			marker.setMap(m_map);
		}
		else
		{
			var marker = new google.maps.Marker({
    			position: LatLngFromCLLocationCoordinate2D([annotation coordinate]),
    			map: m_map
	  		});

  			[markerDictionary setValue:marker forKey:[annotation UID]];
		}

		[annotations addObject:annotation];
	};
}

- (void)removeAnnotation:(MKAnnotation)annotation
{
	[self removeAnnotation:[CPArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(CPArray)aAnnotationArray
{
	var annotationsCount = [aAnnotationArray count];

	for (var i =0; i < annotationsCount; i++)
	{
		var annotation = aAnnotationArray[i]

		if(annotation)
		{
			var marker = [markerDictionary valueForKey:[annotation UID]];

			if(marker)
	  		{
				marker.setMap(null);
				[markerDictionary setValue:null forKey:[annotation UID]];
	  		}

			[annotations removeObject:annotation];
		}
	};
}

-(void)layoutSubviews
{
	google.maps.event.trigger(m_map, 'resize');
}


@end

var GoogleMapsScriptQueue   = [];

var performWhenGoogleMapsScriptLoaded = function(/*Function*/ aFunction)
{
    GoogleMapsScriptQueue.push(aFunction);

    performWhenGoogleMapsScriptLoaded = function()
    {
        GoogleMapsScriptQueue.push(aFunction);
    }

    // Maps is already loaded
    if (window.google && google.maps && google.maps.Map)
        _MKMapViewMapsLoaded();

    else
    {
        var DOMScriptElement = document.createElement("script");

        DOMScriptElement.src = "http://maps.google.com/maps/api/js?sensor=false&callback=_MKMapViewMapsLoaded";
        DOMScriptElement.type = "text/javascript";

        document.getElementsByTagName("head")[0].appendChild(DOMScriptElement);
    }
}

function _MKMapViewMapsLoaded()
{
    performWhenGoogleMapsScriptLoaded = function(/*Function*/ aFunction)
    {
        aFunction();
    }

    var index = 0,
        count = GoogleMapsScriptQueue.length;

    for (; index < count; ++index)
        GoogleMapsScriptQueue[index]();

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

var MKMapViewCenterCoordinateKey    = @"MKMapViewCenterCoordinateKey",
    MKMapViewZoomLevelKey           = @"MKMapViewZoomLevelKey",
    MKMapViewMapTypeKey             = @"MKMapViewMapTypeKey";

@implementation MKMapView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setCenterCoordinate:CLLocationCoordinate2DFromString([aCoder decodeObjectForKey:MKMapViewCenterCoordinateKey])];
        [self setZoomLevel:[aCoder decodeObjectForKey:MKMapViewZoomLevelKey]];
        [self setMapType:[aCoder decodeObjectForKey:MKMapViewMapTypeKey]];
        [self setScrollWheelZoomEnabled:YES];

        [self _init];
        [self _buildDOM];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:CPStringFromCLLocationCoordinate2D([self centerCoordinate]) forKey:MKMapViewCenterCoordinateKey];
    [aCoder encodeObject:[self zoomLevel] forKey:MKMapViewZoomLevelKey];
    [aCoder encodeObject:[self mapType] forKey:MKMapViewMapTypeKey];
}

@end

@implementation MapOptions: CPObject
{
    Object mapObject @accessors;
    CPDictionary options;
}

- (id)init
{
    self = [super init];
    options = [CPDictionary dictionary];
    return self;
}

- (void)setMapObject:(Object)aMapObject // Call only once when the gmap is loaded
{
    mapObject = aMapObject;
    [self _setOptionsFromDictionary:options];
}

- (void)_setOptionsFromDictionary:(CPDictionary)opts
{
CPLogConsole(_cmd + opts + mapObject);
    var keys = [opts allKeys];
    if ([keys count] == 0)
        return;

    var js_options = {};
    [keys enumerateObjectsUsingBlock:function(key, idx)
    {
        var value = [opts objectForKey:key];
        js_options[key] = value;
        [options setObject:value forKey:key]; // Will send KVO notifications for each value
    }];
    
    if (mapObject != null)
        mapObject.setOptions(js_options);
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var dict = [CPDictionary dictionaryWithObject:aValue forKey:aKey];
    [self _setOptionsFromDictionary:dict];
}

- (id)valueForKey:(CPString)aKey
{
    return [options objectForKey:aKey];
}

@end
