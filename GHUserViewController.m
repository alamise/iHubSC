//
//  GHUserViewController.m
//  iGithub
//
//  Created by Oliver Letterer on 06.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHUserViewController.h"
#import "GithubAPI.h"
#import "GHFeedItemWithDescriptionTableViewCell.h"
#import "UICollapsingAndSpinningTableViewCell.h"
#import "GHSingleRepositoryViewController.h"
#import "GHWebViewViewController.h"
#import "NSString+Additions.h"
#import "GHRecentActivityViewController.h"

#define kUITableViewSectionUserData 0
#define kUITableViewSectionRepositories 1
#define kUITableViewSectionWatchedRepositories 2
#define kUITableViewFollowingUsers 3
#define kUITableViewFollowedUsers 4
#define kUITableViewSectionPlan 5
#define kUITableViewNetwork 6

@implementation GHUserViewController

@synthesize repositoriesArray=_repositoriesArray;
@synthesize username=_username, user=_user;
@synthesize watchedRepositoriesArray=_watchedRepositoriesArray, followingUsers=_followingUsers, followedUsers=_followedUsers;
@synthesize lastIndexPathForSingleRepositoryViewController=_lastIndexPathForSingleRepositoryViewController;

#pragma mark - setters and getters

- (BOOL)canFollowUser {
    return ![self.username isEqualToString:[GHAuthenticationManager sharedInstance].username ];
}

- (BOOL)isFollowingUser {
    return [self.followedUsers indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *object = (NSString *)obj;
        if ([object isEqualToString:[GHAuthenticationManager sharedInstance].username]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] != NSNotFound;
}

- (void)setUsername:(NSString *)username {
    [_username release];
    _username = [username copy];
    self.title = self.username;
    
    self.watchedRepositoriesArray = nil;
    self.repositoriesArray = nil;
    self.user = nil;
    self.followingUsers = nil;
    self.followedUsers = nil;
    
    [self downloadUserData];
    [self.tableView reloadData];
}

#pragma mark - Initialization

- (id)initWithUsername:(NSString *)username {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        // Custom initialization
        self.pullToReleaseEnabled = YES;
        self.username = username;
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc {
    [_repositoriesArray release];
    [_username release];
    [_watchedRepositoriesArray release];
    [_followingUsers release];
    [_followedUsers release];
    [_lastIndexPathForSingleRepositoryViewController release];
    [_user release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - target actions

- (void)createRepositoryButtonClicked:(UIBarButtonItem *)button {
    GHCreateRepositoryViewController *createViewController = [[[GHCreateRepositoryViewController alloc] init] autorelease];
    createViewController.delegate = self;
    
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:createViewController] autorelease];
    [self presentModalViewController:navController animated:YES];
}

#pragma mark - instance methods

- (void)downloadUserData {
    _isDownloadingUserData = YES;
    [GHUser userWithName:self.username 
       completionHandler:^(GHUser *user, NSError *error) {
           _isDownloadingUserData = NO;
           if (error) {
               [self handleError:error];
           } else {
               self.user = user;
               [self didReloadData];
               [self.tableView reloadData];
           }
       }];
}

- (void)downloadRepositories {
    [GHRepository repositoriesForUserNamed:self.username 
                         completionHandler:^(NSArray *array, NSError *error) {
                             if (error) {
                                 [self handleError:error];
                             } else {
                                 self.repositoriesArray = array;
                             }
                             [self cacheHeightForTableView];
                             [self didReloadData];
                             [self.tableView reloadData];
                         }];
}

- (void)reloadData {
    self.repositoriesArray = nil;
    self.watchedRepositoriesArray = nil;
    self.followingUsers = nil;
    self.followedUsers = nil;
    [self.tableView reloadData];
    [self downloadUserData];
}

- (void)cacheHeightForTableView {
    NSInteger i = 0;
    for (GHRepository *repo in self.repositoriesArray) {
        CGFloat height = [self heightForDescription:repo.desctiptionRepo] + 50.0;
        
        if (height < 71.0) {
            height = 71.0;
        }
        
        [self cacheHeight:height forRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:kUITableViewSectionRepositories]];
        
        i++;
    }
}

- (void)cacheHeightForWatchedRepositories {
    NSInteger i = 0;
    for (GHRepository *repo in self.watchedRepositoriesArray) {
        CGFloat height = [self heightForDescription:repo.desctiptionRepo] + 50.0;
        
        if (height < 71.0) {
            height = 71.0;
        }
        
        [self cacheHeight:height forRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:kUITableViewSectionWatchedRepositories]];
        
        i++;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[GHAuthenticationManager sharedInstance].username isEqualToString:self.username]) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                                target:self 
                                                                                                action:@selector(createRepositoryButtonClicked:)]
                                                  autorelease];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIExpandableTableViewDatasource

- (BOOL)tableView:(UIExpandableTableView *)tableView canExpandSection:(NSInteger)section {
    return section == kUITableViewSectionRepositories || 
            section == kUITableViewSectionWatchedRepositories || 
            section == kUITableViewSectionPlan ||
            section == kUITableViewFollowingUsers ||
            section == kUITableViewFollowedUsers ||
            section == kUITableViewNetwork;
}

- (BOOL)tableView:(UIExpandableTableView *)tableView needsToDownloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionRepositories) {
        return self.repositoriesArray == nil;
    } else if (section == kUITableViewSectionWatchedRepositories) {
        return self.watchedRepositoriesArray == nil;
    } else if (section == kUITableViewFollowingUsers) {
        return self.followingUsers == nil;
    } else if (section == kUITableViewFollowedUsers) {
        return self.followedUsers == nil;
    } else if (section == kUITableViewNetwork) {
        return self.followedUsers == nil;
    }
    return NO;
}

- (UITableViewCell<UIExpandingTableViewCell> *)tableView:(UIExpandableTableView *)tableView expandingCellForSection:(NSInteger)section {
    NSString *CellIdientifier = @"UICollapsingAndSpinningTableViewCell";
    
    UICollapsingAndSpinningTableViewCell *cell = (UICollapsingAndSpinningTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdientifier];
    
    if (cell == nil) {
        cell = [[[UICollapsingAndSpinningTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdientifier] autorelease];
    }
    
    if (section == kUITableViewSectionRepositories) {
        cell.textLabel.text = NSLocalizedString(@"Repositories", @"");
    } else if (section == kUITableViewSectionWatchedRepositories) {
        cell.textLabel.text = NSLocalizedString(@"Watched Repositories", @"");
    } else if (section == kUITableViewSectionPlan) {
        cell.textLabel.text = NSLocalizedString(@"Plan", @"");
    } else if (section == kUITableViewFollowingUsers) {
        cell.textLabel.text = NSLocalizedString(@"Following", @"");
    } else if (section == kUITableViewFollowedUsers) {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"User following %@", @""), self.username];
    } else if (section == kUITableViewNetwork) {
        cell.textLabel.text = NSLocalizedString(@"Network", @"");
    }
    
    return cell;
}

#pragma mark - UIExpandableTableViewDelegate

- (void)tableView:(UIExpandableTableView *)tableView downloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionRepositories) {
        [GHRepository repositoriesForUserNamed:self.username 
                             completionHandler:^(NSArray *array, NSError *error) {
                                 if (error) {
                                     [self handleError:error];
                                     [tableView cancelDownloadInSection:section];
                                 } else {
                                     self.repositoriesArray = array;
                                     [self cacheHeightForTableView];
                                     [self.tableView expandSection:section animated:YES];
                                 }
                                 [self didReloadData];
                             }];
    } else if (section == kUITableViewSectionWatchedRepositories) {
        [GHRepository watchedRepositoriesOfUser:self.username 
                              completionHandler:^(NSArray *array, NSError *error) {
                                  if (error) {
                                      [self handleError:error];
                                      [tableView cancelDownloadInSection:section];
                                  } else {
                                      self.watchedRepositoriesArray = array;
                                      [self cacheHeightForWatchedRepositories];
                                      [self.tableView expandSection:section animated:YES];
                                  }
                              }];
    } else if (section == kUITableViewFollowingUsers) {
        [GHUser usersFollowingUserNamed:self.username 
                      completionHandler:^(NSArray *users, NSError *error) {
                          if (error) {
                              [self handleError:error];
                              [tableView cancelDownloadInSection:section];
                          } else {
                              self.followingUsers = users;
                              [tableView expandSection:section animated:YES];
                          }
                      }];
    } else if (section == kUITableViewFollowedUsers) {
        [GHUser usersFollowedByUserNamed:self.username 
                       completionHandler:^(NSArray *users, NSError *error) {
                           if (error) {
                               [self handleError:error];
                               [tableView cancelDownloadInSection:section];
                           } else {
                               self.followedUsers = [[users mutableCopy] autorelease];
                               [tableView expandSection:section animated:YES];
                           }
                       }];
    } else if (section == kUITableViewNetwork) {
        [GHUser usersFollowedByUserNamed:self.username 
                       completionHandler:^(NSArray *users, NSError *error) {
                           if (error) {
                               [self handleError:error];
                               [tableView cancelDownloadInSection:section];
                           } else {
                               self.followedUsers = [[users mutableCopy] autorelease];
                               [tableView expandSection:section animated:YES];
                           }
                       }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_isDownloadingUserData || !self.user) {
        return 0;
    }
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSInteger result = 0;
    
    if (section == kUITableViewSectionUserData) {
        result = 6;
    } else if (section == kUITableViewSectionRepositories) {
        result = [self.repositoriesArray count] + 1;
    } else if (section == kUITableViewSectionWatchedRepositories) {
        // watched
        result = [self.watchedRepositoriesArray count] + 1;
    } else if (section == kUITableViewSectionPlan && self.user.planName) {
        result = 5;
    } else if (section == kUITableViewFollowingUsers) {
        if (self.user.followingCount == 0) {
            return 0;
        }
        return [self.followingUsers count] + 1;
    } else if (section == kUITableViewFollowedUsers) {
        if (self.user.followersCount == 0) {
            return 0;
        }
        return [self.followedUsers count] + 1;
    } else if (section == kUITableViewNetwork) {
        if (!self.canFollowUser) {
            return 0;
        } else {
            return 2;
        }
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionUserData) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"TitleTableViewCell";
            
            GHFeedItemWithDescriptionTableViewCell *cell = (GHFeedItemWithDescriptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[GHFeedItemWithDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellEditingStyleNone;
            }
            
            cell.titleLabel.text = self.user.login;
            cell.descriptionLabel.text = nil;
            cell.repositoryLabel.text = nil;
            
            [self updateImageViewForCell:cell atIndexPath:indexPath withGravatarID:self.user.gravatarID];
            
            return cell;
        } 
//        else if (indexPath.row == 5) {
//            // Recent activity
//            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
//            
//            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//            if (!cell) {
//                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
//            }
//            
//            cell.textLabel.text = NSLocalizedString(@"Recent activity", @"");
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//            
//            return cell;
//        } 
        else {
            NSString *CellIdentifier = @"DetailsTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"E-Mail", @"");
                cell.detailTextLabel.text = self.user.EMail ? self.user.EMail : @"-";
            } else if (indexPath.row == 2) {
                cell.textLabel.text = NSLocalizedString(@"Location", @"");
                cell.detailTextLabel.text = self.user.location ? self.user.location : @"-";
            } else if (indexPath.row == 3) {
                cell.textLabel.text = NSLocalizedString(@"Company", @"");
                cell.detailTextLabel.text = self.user.company ? self.user.company : @"-";
            } else if (indexPath.row == 4) {
                cell.textLabel.text = NSLocalizedString(@"Blog", @"");
                cell.detailTextLabel.text = self.user.blog ? self.user.blog : @"-";
                if (self.user.blog) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
            } else if (indexPath.row == 5) {
                cell.textLabel.text = NSLocalizedString(@"Public", @"");
                cell.detailTextLabel.text = NSLocalizedString(@"Activity", @"");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
                cell.textLabel.text = NSLocalizedString(@"XXX", @"");
                cell.detailTextLabel.text = @"-";
            }
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionRepositories) {
        // display all repostories
        NSString *CellIdentifier = @"GHFeedItemWithDescriptionTableViewCell";
        
        GHFeedItemWithDescriptionTableViewCell *cell = (GHFeedItemWithDescriptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[GHFeedItemWithDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        GHRepository *repository = [self.repositoriesArray objectAtIndex:indexPath.row-1];
        
        cell.titleLabel.text = repository.name;
        cell.descriptionLabel.text = repository.desctiptionRepo;
        
        if ([repository.private boolValue]) {
            cell.imageView.image = [UIImage imageNamed:@"GHPrivateRepositoryIcon.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"GHPublicRepositoryIcon.png"];
        }
        
        return cell;
    } else if (indexPath.section == kUITableViewSectionWatchedRepositories) {
        // watched repositories
        if (indexPath.row <= [self.watchedRepositoriesArray count] ) {
            NSString *CellIdentifier = @"GHFeedItemWithDescriptionTableViewCell";
            
            GHFeedItemWithDescriptionTableViewCell *cell = (GHFeedItemWithDescriptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[GHFeedItemWithDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHRepository *repository = [self.watchedRepositoriesArray objectAtIndex:indexPath.row-1];
            
            cell.titleLabel.text = [NSString stringWithFormat:@"%@/%@", repository.owner, repository.name];
            
            cell.descriptionLabel.text = repository.desctiptionRepo;
            
            if ([repository.private boolValue]) {
                cell.imageView.image = [UIImage imageNamed:@"GHPrivateRepositoryIcon.png"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"GHPublicRepositoryIcon.png"];
            }
            
            // Configure the cell...
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionPlan) {
        NSString *CellIdentifier = @"DetailsTableViewCell";
        
        UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Type", @"");
            cell.detailTextLabel.text = self.user.planName;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Private Repos", @"");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.user.planPrivateRepos];
        } else if (indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"Collaborators", @"");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.user.planCollaborators];
        } else if (indexPath.row == 4) {
            cell.textLabel.text = NSLocalizedString(@"Space", @"");
            cell.detailTextLabel.text = [[NSString stringFormFileSize:self.user.planSpace] stringByAppendingFormat:NSLocalizedString(@" used", @"")];
        } else {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
        }
        return cell;
    } else if (indexPath.section == kUITableViewFollowingUsers) {
        NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
        
        UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        
        NSString *username = [self.followingUsers objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = username;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    } else if (indexPath.section == kUITableViewFollowedUsers) {
        NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
        
        UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        
        NSString *username = [self.followedUsers objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = username;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    } else if (indexPath.section == kUITableViewNetwork) {
        NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundViewNetwork2";
        
        UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.textLabel.text = self.isFollowingUser ? NSLocalizedString(@"Unfollow", @"") : NSLocalizedString(@"Follow", @"");
        
        return cell;
    }
    
    return self.dummyCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionUserData) {
        if (indexPath.row == 4 && self.user.blog) {
            NSURL *URL = [NSURL URLWithString:self.user.blog];
            GHWebViewViewController *web = [[[GHWebViewViewController alloc] initWithURL:URL] autorelease];
            [self.navigationController pushViewController:web animated:YES];
        } else if (indexPath.row == 5) {
            GHRecentActivityViewController *recentViewController = [[[GHRecentActivityViewController alloc] initWithUsername:self.username] autorelease];
            [self.navigationController pushViewController:recentViewController animated:YES];
        }
    }
    if (indexPath.section == kUITableViewSectionRepositories) {
        GHRepository *repo = [self.repositoriesArray objectAtIndex:indexPath.row-1];
        
        GHSingleRepositoryViewController *viewController = [[[GHSingleRepositoryViewController alloc] initWithRepositoryString:[NSString stringWithFormat:@"%@/%@", repo.owner, repo.name] ] autorelease];
        viewController.delegate = self;
        self.lastIndexPathForSingleRepositoryViewController = indexPath;
        [self.navigationController pushViewController:viewController animated:YES];
        
    } else if (indexPath.section == kUITableViewSectionWatchedRepositories) {
        GHRepository *repo = [self.watchedRepositoriesArray objectAtIndex:indexPath.row-1];
        
        GHSingleRepositoryViewController *viewController = [[[GHSingleRepositoryViewController alloc] initWithRepositoryString:[NSString stringWithFormat:@"%@/%@", repo.owner, repo.name] ] autorelease];
        viewController.delegate = self;
        self.lastIndexPathForSingleRepositoryViewController = indexPath;
        [self.navigationController pushViewController:viewController animated:YES];
    } else if (indexPath.section == kUITableViewFollowingUsers) {
        NSString *username = [self.followingUsers objectAtIndex:indexPath.row - 1];
        
        GHUserViewController *userViewController = [[[GHUserViewController alloc] initWithUsername:username] autorelease];
        [self.navigationController pushViewController:userViewController animated:YES];
        
    } else if (indexPath.section == kUITableViewFollowedUsers) {
        NSString *username = [self.followedUsers objectAtIndex:indexPath.row - 1];
        
        GHUserViewController *userViewController = [[[GHUserViewController alloc] initWithUsername:username] autorelease];
        [self.navigationController pushViewController:userViewController animated:YES];
        
    } else if (indexPath.section == kUITableViewNetwork) {
        if (self.isFollowingUser) {
            [GHUser unfollowUser:self.username 
               completionHandler:^(NSError *error) {
                   if (error) {
                       [self handleError:error];
                   } else {
                       NSUInteger index = [self.followedUsers indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                           if ([[GHAuthenticationManager sharedInstance].username isEqualToString:obj]) {
                               *stop = YES;
                               return YES;
                           }
                           return NO;
                       }];
                       if (index != NSNotFound) {
                           [self.followedUsers removeObjectAtIndex:index];
                           NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
                           [set addIndex:kUITableViewNetwork];
                           [set addIndex:kUITableViewFollowedUsers];
                           [self.tableView reloadSections:set 
                                         withRowAnimation:UITableViewRowAnimationNone];
                       }
                   }
               }];
        } else {
            [GHUser followUser:self.username 
               completionHandler:^(NSError *error) {
                   if (error) {
                       [self handleError:error];
                   } else {
                       NSUInteger index = [self.followedUsers indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                           if ([[GHAuthenticationManager sharedInstance].username isEqualToString:obj]) {
                               *stop = YES;
                               return YES;
                           }
                           return NO;
                       }];
                       if (index == NSNotFound) {
                           [self.followedUsers addObject:[GHAuthenticationManager sharedInstance].username ];
                           NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
                           [set addIndex:kUITableViewNetwork];
                           [set addIndex:kUITableViewFollowedUsers];
                           [self.tableView reloadSections:set 
                                         withRowAnimation:UITableViewRowAnimationNone];
                       }
                   }
               }];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionUserData && indexPath.row == 0) {
        return 71.0f;
    }
    if (indexPath.section == kUITableViewSectionRepositories) {
        if (indexPath.row == 0) {
            return 44.0f;
        }
        return [self cachedHeightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == kUITableViewSectionWatchedRepositories) {
        if (indexPath.row == 0) {
            return 44.0f;
        }
        // watched repo
        return [self cachedHeightForRowAtIndexPath:indexPath];
    }
    return 44.0;
}

#pragma mark - GHCreateRepositoryViewControllerDelegate

- (void)createRepositoryViewController:(GHCreateRepositoryViewController *)createRepositoryViewController 
                   didCreateRepository:(GHRepository *)repository {
    [self dismissModalViewControllerAnimated:YES];
    [self downloadRepositories];
}

- (void)createRepositoryViewControllerDidCancel:(GHCreateRepositoryViewController *)createRepositoryViewController {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - GHSingleRepositoryViewControllerDelegate

- (void)singleRepositoryViewControllerDidDeleteRepository:(GHSingleRepositoryViewController *)singleRepositoryViewController {
    
    NSArray *oldArray = self.lastIndexPathForSingleRepositoryViewController.section == kUITableViewSectionRepositories ? self.repositoriesArray : self.watchedRepositoriesArray;
    NSUInteger index = self.lastIndexPathForSingleRepositoryViewController.row;
    
    NSMutableArray *array = [[oldArray mutableCopy] autorelease];
    [array removeObjectAtIndex:index];

    if (self.lastIndexPathForSingleRepositoryViewController.section == kUITableViewSectionRepositories) {
        self.repositoriesArray = array;
    } else {
        self.watchedRepositoriesArray = array;
    }
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.lastIndexPathForSingleRepositoryViewController] 
                          withRowAnimation:UITableViewRowAnimationTop];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end