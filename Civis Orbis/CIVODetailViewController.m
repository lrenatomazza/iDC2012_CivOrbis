//
//  CIVODetailViewController.m
//  Civis Orbis
//
//  Created by Kris Markel on 7/21/12.
/*

Copyright (c) 2012, Nelson Ferraz and Kris Markel
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	• Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	• Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
//

#import "CIVODetailViewController.h"

#import "City.h"
#import "CIVOPOIViewController.h"
#import "CIVOToursViewController.h"
#import "POI.h"

const float CIVOInitialMapZoomLevel = 0.225;
const NSTimeInterval CIVOTimeIntervalBeforeHidingNavBar = 3.0;

@interface CIVODetailViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) CIVOPOIViewController *POIViewController;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *mapImageView;

@property (strong, nonatomic) NSTimer *hideNavbarTimer;

@property (nonatomic, strong) NSArray *POIs;

- (IBAction)toursButtonTapped:(id)sender;

- (void) configureView;
- (void) handlePinTap: (UIGestureRecognizer *)gestureRecognizer;
- (void) handleScrollViewTap: (UIGestureRecognizer *) gestureRecognizer;
- (void) handleHideNavBarTimerFired: (NSTimer *) timer;

@end

@implementation CIVODetailViewController

#pragma mark - Managing the detail item
@synthesize scrollView;
@synthesize mapImageView;

@synthesize city = _city;
@synthesize POIViewController = _POIViewController;
@synthesize hideNavbarTimer = _hideNavbarTimer;
@synthesize POIs = _POIs;

- (void) dealloc
{
	[_hideNavbarTimer invalidate];
}

- (void)setCity:(City *)newCity
{
    if (_city != newCity) {
        _city = newCity;
		 
		 // We need to put the POIs in a array so we can grab them by index.
		 self.POIs = [_city.pois allObjects];
        
        // Update the view.
        [self configureView];
    }
}

- (IBAction)toursButtonTapped:(id)sender {
	
	CIVOToursViewController *toursVC = [[CIVOToursViewController alloc] initWithNibName:nil bundle:nil];
	[self presentModalViewController:toursVC animated:YES];
	
}

- (void)configureView
{
	if (!self.isViewLoaded) {
		return;
	}
	
	// Update the user interface for the detail item.
	self.title = self.city.name;
	
	// We have to reset the zoom scale to 1 or all our frame calculations are off.
	self.scrollView.zoomScale = 1.0;
	
	NSString *mapFileName = [NSString stringWithFormat:@"%@.jpg", self.city.mapFile];
	UIImage *mapImage = [UIImage imageNamed:mapFileName];
	self.mapImageView.frame = (CGRect) {
		.origin = self.mapImageView.frame.origin,
		.size = mapImage.size,
	};
	self.mapImageView.image = mapImage;

	// Remove old POIs.
	for (UIView *subview in self.mapImageView.subviews) {
		[subview removeFromSuperview];
	}
	
	// Place the pins:
	for (POI *poi in self.POIs) {

		UIImage *pinImage = [UIImage imageNamed:@"pin.png"];
		UIImageView *pinView = [[UIImageView alloc] initWithImage:pinImage];
		pinView.userInteractionEnabled = YES;
		// TAGHACK: We're storing the POI index in the tag.
		pinView.tag = [self.POIs indexOfObject:poi];
		
		CGPoint pinPoint = CGPointFromString(poi.mapPoint);
		// The bottom left of the pin is the bit that belongs on the point.
		pinPoint = CGPointMake(pinPoint.x + (pinImage.size.width / 2), pinPoint.y - (pinImage.size.height / 2));
		pinView.center = pinPoint;
		[self.mapImageView addSubview:pinView];
		
		UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinTap:)];
		[pinView addGestureRecognizer:tapRecognizer];
	}
	
	self.scrollView.contentSize = self.mapImageView.image.size;
	self.scrollView.zoomScale = CIVOInitialMapZoomLevel;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollViewTap:)];
	[self.scrollView addGestureRecognizer:tapRecognizer];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.hideNavbarTimer invalidate];
	self.hideNavbarTimer = [NSTimer scheduledTimerWithTimeInterval:CIVOTimeIntervalBeforeHidingNavBar target:self selector:@selector(handleHideNavBarTimerFired:) userInfo:nil repeats:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[self.hideNavbarTimer invalidate];
}

- (void)viewDidUnload
{
	[self setMapImageView:nil];
	[self setScrollView:nil];
	[super viewDidUnload];
	// Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Map", @"Map");
    }
    return self;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.mapImageView;
}
		
#pragma mark - Gesture recognizers

- (void) handlePinTap: (UIGestureRecognizer *)gestureRecognizer
{
	
	if (!self.POIViewController) {
		self.POIViewController = [[CIVOPOIViewController alloc] initWithNibName:nil bundle:nil];
	}

	POI *POI = [self.POIs objectAtIndex:gestureRecognizer.view.tag];
	self.POIViewController.POI = POI;
	[self.navigationController pushViewController:self.POIViewController animated:YES];
	
}

- (void) handleScrollViewTap: (UIGestureRecognizer *) gestureRecognizer
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.hideNavbarTimer invalidate];
	self.hideNavbarTimer = [NSTimer scheduledTimerWithTimeInterval:CIVOTimeIntervalBeforeHidingNavBar target:self selector:@selector(handleHideNavBarTimerFired:) userInfo:nil repeats:NO];
}

									
									
#pragma mark - Timer handlers
									
- (void) handleHideNavBarTimerFired: (NSTimer *) timer
{
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}
									
									
@end
