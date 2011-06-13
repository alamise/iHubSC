//
//  GHSingleRepositoryViewController.m
//  iGithub
//
//  Created by Oliver Letterer on 09.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHSingleRepositoryViewController.h"
#import "GHFeedItemWithDescriptionTableViewCell.h"
#import "NSString+Additions.h"
#import "GHWebViewViewController.h"
#import "UICollapsingAndSpinningTableViewCell.h"
#import "GHIssueTitleTableViewCell.h"
#import "GHViewIssueTableViewController.h"
#import "GHNewsFeedItemTableViewCell.h"
#import "GHUserViewController.h"
#import "GHRecentCommitsViewController.h"
#import "GHViewRootDirectoryViewController.h"
#import "GHAPIMilestoneV3TableViewCell.h"
#import "GHViewMilestoneViewController.h"
#import "GHLabelTableViewCell.h"
#import "GHViewLabelViewController.h"
#import "OCPromptView.h"

#define kUITableViewSectionUserData         0
#define kUITableViewSectionOwner            1
#define kUITableViewSectionLanguage         2
#define kUITableViewSectionCreatedAt        3
#define kUITableViewSectionSize             4
#define kUITableViewSectionHomepage         5
#define kUITableViewSectionForkedFrom       6
#define kUITableViewSectionIssues           7
#define kUITableViewSectionMilestones       8
#define kUITableViewSectionLabels           9
#define kUITableViewSectionWatchingUsers    10
#define kUITableViewSectionPullRequests     11
#define kUITableViewSectionRecentCommits    12
#define kUITableViewSectionBrowseBranches   13
#define kUITableViewSectionCollaborators    14
#define kUITableViewSectionNetwork          15
#define kUITableViewSectionAdministration   16

#define kUITableViewNumberOfSections        17

#define kUIAlertViewAddCollaboratorTag      1337

@implementation GHSingleRepositoryViewController

@synthesize repositoryString=_repositoryString, repository=_repository, issuesArray=_issuesArray, watchedUsersArray=_watchedUsersArray, deleteToken=_deleteToken, delegate=_delegate;
@synthesize pullRequests=_pullRequests, branches=_branches, milestones=_milestones, labels=_labels, organizations=_organizations, collaborators=_collaborators;

#pragma mark - setters and getters

- (void)setRepositoryString:(NSString *)repositoryString {
    [_repositoryString release];
    _repositoryString = [repositoryString copy];
    [self pullToReleaseTableViewReloadData];
}

- (BOOL)canDeleteRepository {
    return [self.repository.owner.login isEqualToString:[GHAuthenticationManager sharedInstance].username ];
}

- (BOOL)isFollowingRepository {
    return [self.watchedUsersArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[GHAuthenticationManager sharedInstance].username isEqualToString:obj]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] != NSNotFound;
}

#pragma mark - Initialization

- (id)initWithRepositoryString:(NSString *)repositoryString {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        // Custom initialization
        self.repositoryString = repositoryString;
        self.title = [[self.repositoryString componentsSeparatedByString:@"/"] lastObject];
    }
    return self;
}

#pragma mark - instance methods

- (void)pullToReleaseTableViewReloadData {
    [super pullToReleaseTableViewReloadData];
    [GHAPIRepositoryV3 repositoryNamed:self.repositoryString 
                 withCompletionHandler:^(GHAPIRepositoryV3 *repository, NSError *error) {
                     if (error) {
                         [self handleError:error];
                     } else {
                         self.repository = repository;
                         [self.tableView reloadData];
                     }
                     [self pullToReleaseTableViewDidReloadData];
                 }];
}

#pragma mark - Memory management

- (void)dealloc {
    [_repositoryString release];
    [_repository release];
    [_issuesArray release];
    [_watchedUsersArray release];
    [_deleteToken release];
    [_pullRequests release];
    [_branches release];
    [_labels release];
    [_milestones release];
    [_organizations release];
    [_collaborators release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return section != kUITableViewSectionUserData && section != kUITableViewSectionOwner && section != kUITableViewSectionLanguage && section != kUITableViewSectionCreatedAt && section != kUITableViewSectionSize && section != kUITableViewSectionHomepage && section != kUITableViewSectionForkedFrom;
}
- (BOOL)tableView:(UIExpandableTableView *)tableView needsToDownloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionIssues) {
        return self.issuesArray == nil;
    } else if (section == kUITableViewSectionWatchingUsers) {
        return self.watchedUsersArray == nil;
    } else if (section == kUITableViewSectionAdministration) {
        return NO;
    } else if (section == kUITableViewSectionNetwork) {
        return !_hasWatchingData;
    } else if (section == kUITableViewSectionPullRequests) {
        return self.pullRequests == nil;
    } else if (section == kUITableViewSectionRecentCommits) {
        return self.branches == nil;
    } else if (section == kUITableViewSectionBrowseBranches) {
        return self.branches == nil;
    } else if (section == kUITableViewSectionMilestones) {
        return self.milestones == nil;
    } else if (section == kUITableViewSectionLabels) {
        return self.labels == nil;
    } else if (section == kUITableViewSectionCollaborators) {
        return self.collaborators == nil;
    }
    return NO;
}

- (UITableViewCell<UIExpandingTableViewCell> *)tableView:(UIExpandableTableView *)tableView expandingCellForSection:(NSInteger)section {
    NSString *CellIdientifier = @"UICollapsingAndSpinningTableViewCell";
    
    UICollapsingAndSpinningTableViewCell *cell = (UICollapsingAndSpinningTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdientifier];
    
    if (cell == nil) {
        cell = [[[UICollapsingAndSpinningTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdientifier] autorelease];
    }
    
    if (section == kUITableViewSectionIssues) {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Open Issues (%@)", @""), self.repository.openIssues];
    } else if (section == kUITableViewSectionWatchingUsers) {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Watching Users (%@)", @""), self.repository.watchers];
    } else if (section == kUITableViewSectionAdministration) {
        cell.textLabel.text = NSLocalizedString(@"Administration", @"");
    } else if (section == kUITableViewSectionNetwork) {
        cell.textLabel.text = NSLocalizedString(@"Network", @"");
    } else if (section == kUITableViewSectionPullRequests) {
        cell.textLabel.text = NSLocalizedString(@"Pull Requests", @"");
    } else if (section == kUITableViewSectionRecentCommits) {
        cell.textLabel.text = NSLocalizedString(@"Recent Commits", @"");
    } else if (section == kUITableViewSectionBrowseBranches) {
        cell.textLabel.text = NSLocalizedString(@"Browse Content", @"");
    } else if (section == kUITableViewSectionMilestones) {
        cell.textLabel.text = NSLocalizedString(@"Milestones", @"");
    } else if (section == kUITableViewSectionLabels) {
        cell.textLabel.text = NSLocalizedString(@"Labels", @"");
    } else if (section == kUITableViewSectionCollaborators) {
        cell.textLabel.text = NSLocalizedString(@"Collaborators", @"");
    }
    
    return cell;
}

#pragma mark - UIExpandableTableViewDelegate

- (void)tableView:(UIExpandableTableView *)tableView downloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionIssues) {
        [GHAPIIssueV3 openedIssuesOnRepository:self.repositoryString page:1 
                             completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                 if (error) {
                                     [self handleError:error];
                                     [tableView cancelDownloadInSection:section];
                                 } else {
                                     self.issuesArray = array;
                                     [self setNextPage:nextPage forSection:section];
                                     [self cacheHeightForIssuesArray];
                                     [tableView expandSection:section animated:YES];
                                 }
                             }];
    } else if (section == kUITableViewSectionWatchingUsers) {
        [GHAPIRepositoryV3 watchersOfRepository:self.repositoryString page:1 
                              completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                  if (error) {
                                      [tableView cancelDownloadInSection:section];
                                      [self handleError:error];
                                  } else {
                                      self.watchedUsersArray = array;
                                      [self setNextPage:nextPage forSection:section];
                                      [tableView expandSection:section animated:YES];
                                  }
                              }];
    } else if (section == kUITableViewSectionNetwork) {
        [GHAPIRepositoryV3 isWatchingRepository:self.repositoryString 
                              completionHandler:^(BOOL watching, NSError *error) {
                                  if (error) {
                                      [self handleError:error];
                                      [tableView cancelDownloadInSection:section];
                                  } else {
                                      _hasWatchingData = YES;
                                      _isWatchingRepository = watching;
                                      [tableView expandSection:section animated:YES];
                                  }
                              }];
    } else if (section == kUITableViewSectionPullRequests) {
        [GHPullRequest pullRequestsOnRepository:self.repositoryString 
                              completionHandler:^(NSArray *requests, NSError *error) {
                                  if (error) {
                                      [tableView cancelDownloadInSection:section];
                                      [self handleError:error];
                                  } else {
                                      self.pullRequests = requests;
                                      [self cacheHeightForPullRequests];
                                      [self.tableView expandSection:section animated:YES];
                                      
                                      if ([self.pullRequests count] == 0) {
                                          UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") 
                                                                                           message:NSLocalizedString(@"This repository does not have any Pull Requests.", @"") 
                                                                                          delegate:nil 
                                                                                 cancelButtonTitle:NSLocalizedString(@"OK", @"") 
                                                                                 otherButtonTitles:nil]
                                                                autorelease];
                                          [alert show];
                                      }
                                  }
                              }];
    } else if (section == kUITableViewSectionRecentCommits || section == kUITableViewSectionBrowseBranches) {
        [GHAPIRepositoryV3 branchesOnRepository:self.repositoryString page:1 
                              completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                  if (error) {
                                      [self handleError:error];
                                      [tableView cancelDownloadInSection:section];
                                  } else {
                                      self.branches = array;
                                      [self setNextPage:nextPage forSection:section];
                                      [tableView expandSection:section animated:YES];
                                  }
                              }];
    } else if (section == kUITableViewSectionMilestones) {
        [GHAPIIssueV3 milestonesForIssueOnRepository:self.repositoryString withNumber:nil page:1 
                                   completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                       if (error) {
                                           [self handleError:error];
                                           [tableView cancelDownloadInSection:section];
                                       } else {
                                           self.milestones = array;
                                           [self setNextPage:nextPage forSection:section];
                                           [tableView expandSection:section animated:YES];
                                       }
                                   }];
    } else if (section == kUITableViewSectionLabels) {
        [GHAPIRepositoryV3 labelsOnRepository:self.repositoryString 
                                         page:1 
                            completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                if (error) {
                                    [tableView cancelDownloadInSection:section];
                                    [self handleError:error];
                                } else {
                                    self.labels = array;
                                    [self setNextPage:nextPage forSection:section];
                                    [tableView expandSection:section animated:YES];
                                }
                            }];
    } else if (section == kUITableViewSectionCollaborators) {
        [GHAPIRepositoryV3 collaboratorsForRepository:self.repositoryString page:1 
                                    completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                        if (error) {
                                            [tableView cancelDownloadInSection:section];
                                            [self handleError:error];
                                        } else {
                                            self.collaborators = array;
                                            [self setNextPage:nextPage forSection:section];
                                            [tableView expandSection:section animated:YES];
                                        }
                                    }];
    }
}

#pragma mark - pagination

- (void)downloadDataForPage:(NSUInteger)page inSection:(NSUInteger)section {
    if (section == kUITableViewSectionLabels) {
        [GHAPIRepositoryV3 labelsOnRepository:self.repositoryString 
                                         page:page 
                            completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                if (error) {
                                    [self handleError:error];
                                } else {
                                    [self setNextPage:nextPage forSection:section];
                                    [self.labels addObjectsFromArray:array];
                                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                                                  withRowAnimation:UITableViewScrollPositionBottom];
                                }
                            }];
    } else if (section == kUITableViewSectionRecentCommits || section == kUITableViewSectionBrowseBranches) {
        [GHAPIRepositoryV3 branchesOnRepository:self.repositoryString page:page 
                              completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                  if (error) {
                                      [self handleError:error];
                                  } else {
                                      [self.branches addObjectsFromArray:array];
                                      [self setNextPage:nextPage forSection:section];
                                      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                                                    withRowAnimation:UITableViewScrollPositionBottom];
                                  }
                              }];
    } else if (section == kUITableViewSectionIssues) {
        [GHAPIIssueV3 openedIssuesOnRepository:self.repositoryString page:page 
                             completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                 if (error) {
                                     [self handleError:error];
                                 } else {
                                     [self.issuesArray addObjectsFromArray:array];
                                     [self setNextPage:nextPage forSection:section];
                                     [self cacheHeightForIssuesArray];
                                     [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] 
                                                   withRowAnimation:UITableViewScrollPositionBottom];
                                 }
                             }];
    } else if (section == kUITableViewSectionMilestones) {
        [GHAPIIssueV3 milestonesForIssueOnRepository:self.repositoryString withNumber:nil page:1 
                                   completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                       if (error) {
                                           [self handleError:error];
                                       } else {
                                           [self.milestones addObjectsFromArray:array];
                                           [self setNextPage:nextPage forSection:section];
                                           [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] 
                                                         withRowAnimation:UITableViewScrollPositionBottom];
                                       }
                                   }];
    } else if (section == kUITableViewSectionCollaborators) {
        [GHAPIRepositoryV3 collaboratorsForRepository:self.repositoryString page:page 
                                    completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                        if (error) {
                                            [self handleError:error];
                                        } else {
                                            [self.collaborators addObjectsFromArray:array];
                                            [self setNextPage:nextPage forSection:section];
                                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] 
                                                          withRowAnimation:UITableViewScrollPositionBottom];
                                        }
                                    }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (!self.repository) {
        return 0;
    }
    
    return kUITableViewNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == kUITableViewSectionUserData) {
        // title + description
        return 1;
    } else if (section == kUITableViewSectionIssues) {
        // issues
        // title, issues, create new issue
        if ([self.repository.openIssues unsignedIntValue] == 0) {
            return 0;
        }
        return [self.issuesArray count] + 2;
    } else if (section == kUITableViewSectionWatchingUsers) {
        if ([self.repository.watchers intValue] == 0) {
            return 0;
        }
        return [self.watchedUsersArray count] + 1;
    } else if (section == kUITableViewSectionAdministration) {
        if (self.canDeleteRepository) {
            return 2;
        }
    } else if (section == kUITableViewSectionNetwork) {
        if (!self.canDeleteRepository) {
            return 4;
        }
    } else if (section == kUITableViewSectionPullRequests) {
        return [self.pullRequests count] + 1;
    } else if (section == kUITableViewSectionRecentCommits || section == kUITableViewSectionBrowseBranches) {
        return [self.branches count] + 1;
    } else if (section == kUITableViewSectionMilestones) {
        return self.milestones.count + 1;
    } else if (section == kUITableViewSectionLabels) {
        return self.labels.count + 1;
    } else if (section == kUITableViewSectionOwner) {
        return 1;
    } else if (section == kUITableViewSectionLanguage) {
        if (self.repository.hasLanguage) {
            return 1;
        }
    } else if (section == kUITableViewSectionCreatedAt) {
        return 1;
    } else if (section == kUITableViewSectionSize) {
        return 1;
    } else if (section == kUITableViewSectionHomepage) {
        if (self.repository.hasHomepage) {
            return 1;
        }
    } else if (section == kUITableViewSectionForkedFrom) {
        if (self.repository.isForked) {
            return 1;
        }
    } else if (section == kUITableViewSectionCollaborators) {
        if (!self.canDeleteRepository) {
            return 0;
        }
        return self.collaborators.count + 2;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == kUITableViewSectionUserData) {
        if (indexPath.row == 0) {
            // title + description
            NSString *CellIdentifier = @"GHFeedItemWithDescriptionTableViewCell";
            
            GHFeedItemWithDescriptionTableViewCell *cell = (GHFeedItemWithDescriptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[GHFeedItemWithDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.selectionStyle = UITableViewCellEditingStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            if (self.repository.isForked) {
                cell.titleLabel.text = [NSString stringWithFormat:@"%@/%@", self.repository.owner.login, self.repository.name];
                cell.descriptionLabel.text = self.repository.description;
                cell.repositoryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"forked from %@", @""), [NSString stringWithFormat:@"%@/%@", self.repository.parent.owner.login, self.repository.parent.name]];
            } else {
                cell.titleLabel.text = self.repository.name;
                cell.descriptionLabel.text = self.repository.description;
                cell.repositoryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Created by %@", @""), self.repository.owner.login];
            }
            
            if ([self.repository.private boolValue]) {
                cell.imageView.image = [UIImage imageNamed:@"GHPrivateRepositoryIcon.png"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"GHPublicRepositoryIcon.png"];
            }
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionOwner) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsOwnerTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Owner", @"");
            cell.detailTextLabel.text = self.repository.owner.login;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionLanguage) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell.textLabel.text = NSLocalizedString(@"Language", @"");
            cell.detailTextLabel.text = self.repository.language;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionCreatedAt) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell.textLabel.text = NSLocalizedString(@"Created", @"");
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ago", @""), self.repository.createdAt.prettyTimeIntervalSinceNow];
            
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionSize) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell.textLabel.text = NSLocalizedString(@"Size", @"");
            cell.detailTextLabel.text = [NSString stringFormFileSize:[self.repository.size longLongValue] ];
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionHomepage) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsHomePageTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Homepage", @"");
            cell.detailTextLabel.text = self.repository.homepage;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionForkedFrom) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"DetailsHomePageTableViewCell";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Forked from", @"");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@", self.repository.parent.owner.login, self.repository.parent.name];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionIssues) {
        // issues
        if (indexPath.row == 1) {
            // new issue
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Create a new Issue", @"");
            
            return cell;
        } else {
            NSString *CellIdentifier = @"GHIssueTitleTableViewCell";
            GHIssueTitleTableViewCell *cell = (GHIssueTitleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[GHIssueTitleTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHAPIIssueV3 *issue = [self.issuesArray objectAtIndex:indexPath.row - 2];
            
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Issue %@", @""), issue.number];
            
            [self updateImageViewForCell:cell 
                             atIndexPath:indexPath 
                          withGravatarID:issue.user.gravatarID];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"by %@ %@", issue.user.login, [NSString stringWithFormat:NSLocalizedString(@"%@ ago", @""), issue.createdAt.prettyTimeIntervalSinceNow]];
            ;
            
            cell.descriptionLabel.text = issue.title;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionCollaborators) {
        if (indexPath.row == 1) {
            // new Collaborator
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Add new Collaborator", @"");
            
            return cell;
        } else {
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundViewCollaborator";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHAPIUserV3 *user = [self.collaborators objectAtIndex:indexPath.row - 2];
            
            cell.textLabel.text = user.login;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionWatchingUsers) {
        // watching users
        if (indexPath.row > 0 && indexPath.row <= [self.watchedUsersArray count]) {
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHAPIUserV3 *user = [self.watchedUsersArray objectAtIndex:indexPath.row - 1];
            
            cell.textLabel.text = user.login;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionAdministration) {
        // adminsitration
        if (indexPath.row == 1) {
            // first administration
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundViewAdmin";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Delete this Repository", @"");
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionNetwork) {
        NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundViewAdmin";
        
        UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if (indexPath.row == 1) {
            cell.textLabel.text = _isWatchingRepository ? NSLocalizedString(@"Unwatch", @"") : NSLocalizedString(@"Watch", @"") ;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Fork to my Account", @"");
        } else if (indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"Fork to an Organization", @"");
        }
        
        return cell;
        
    } else if (indexPath.section == kUITableViewSectionPullRequests) {
        NSString *CellIdentifier = @"GHFeedItemWithDescriptionTableViewCell";
        
        GHFeedItemWithDescriptionTableViewCell *cell = (GHFeedItemWithDescriptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[GHFeedItemWithDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        GHPullRequestDiscussion *discussion = [self.pullRequests objectAtIndex:indexPath.row-1];
        
        cell.titleLabel.text = discussion.user.login;
        cell.descriptionLabel.text = discussion.title;
        
        cell.repositoryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ago", @""), discussion.createdAt.prettyTimeIntervalSinceNow];
        
        [self updateImageViewForCell:cell 
                         atIndexPath:indexPath 
                      withGravatarID:discussion.user.gravatarID];
        
        return cell;
    } else if (indexPath.section == kUITableViewSectionRecentCommits || indexPath.section == kUITableViewSectionBrowseBranches) {
        if (indexPath.row > 0) {
            NSString *CellIdentifier = @"UITableViewCellWithLinearGradientBackgroundView";
            
            UITableViewCellWithLinearGradientBackgroundView *cell = (UITableViewCellWithLinearGradientBackgroundView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[UITableViewCellWithLinearGradientBackgroundView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHAPIRepositoryBranchV3 *branch = [self.branches objectAtIndex:indexPath.row - 1];
            
            cell.textLabel.text = branch.name;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
    } else if (indexPath.section == kUITableViewSectionMilestones) {
        NSString *CellIdentifier = @"MilestoneCell";
        
        GHAPIMilestoneV3TableViewCell *cell = (GHAPIMilestoneV3TableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[[GHAPIMilestoneV3TableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        GHAPIMilestoneV3 *milestone = [self.milestones objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = milestone.title;
        cell.detailTextLabel.text = milestone.dueFormattedString;
        cell.progressView.progress = [milestone.closedIssues floatValue] / ([milestone.closedIssues floatValue] + [milestone.openIssues floatValue]);
        if (milestone.dueInTime) {
            [cell.progressView setTintColor:[UIColor greenColor] ];
        } else {
            [cell.progressView setTintColor:[UIColor redColor] ];
        }
        
        return cell;
    } else if (indexPath.section == kUITableViewSectionLabels) {
        if (indexPath.row > 0) {
            NSString *CellIdentifier = @"GHLabelTableViewCell";
            
            GHLabelTableViewCell *cell = (GHLabelTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[[GHLabelTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            GHAPILabelV3 *label = [self.labels objectAtIndex:indexPath.row - 1];
            
            cell.textLabel.text = label.name;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.colorView.backgroundColor = label.colorString.colorFromAPIColorString;
            
            return cell;
        }
    }
    
    return self.dummyCell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.section == kUITableViewSectionCollaborators && indexPath.row > 1;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        GHAPIUserV3 *user = [self.collaborators objectAtIndex:indexPath.row - 2];
        
        [GHAPIRepositoryV3 deleteCollaboratorNamed:user.login onRepository:self.repositoryString 
                                 completionHandler:^(NSError *error) {
                                     if (error) {
                                         [self handleError:error];
                                     } else {
                                         [self.collaborators removeObjectAtIndex:indexPath.row - 2];
                                         [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                     }
                                 }];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == kUITableViewSectionUserData && indexPath.row == 0) {
        // title + description
        if (![self isHeightCachedForRowAtIndexPath:indexPath]) {
            [self cacheHeight:[self heightForDescription:self.repository.description] + 50.0 
            forRowAtIndexPath:indexPath];
        }
        
        return [self cachedHeightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == kUITableViewSectionIssues && indexPath.row > 1 && indexPath.row <= [self.issuesArray count]+1) {
        return [self cachedHeightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == kUITableViewSectionPullRequests && indexPath.row > 0 && indexPath.row <= [self.pullRequests count]) {
        return [self cachedHeightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == kUITableViewSectionMilestones && indexPath.row > 0) {
        return GHAPIMilestoneV3TableViewCellHeight;
    }
    
    return 44.0f;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionForkedFrom && indexPath.row == 0) {
        GHSingleRepositoryViewController *repoViewController = [[[GHSingleRepositoryViewController alloc] initWithRepositoryString:[NSString stringWithFormat:@"%@/%@", self.repository.parent.owner.login, self.repository.parent.name] ] autorelease];
        repoViewController.delegate = self;
        [self.navigationController pushViewController:repoViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionOwner && indexPath.row == 0) {
        GHUserViewController *userViewController = [[[GHUserViewController alloc] initWithUsername:self.repository.owner.login] autorelease];
        [self.navigationController pushViewController:userViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionHomepage && indexPath.row == 0) {
        NSURL *URL = [NSURL URLWithString:self.repository.homepage];
        
        GHWebViewViewController *webViewController = [[[GHWebViewViewController alloc] initWithURL:URL] autorelease];
        [self.navigationController pushViewController:webViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionIssues) {
        if (indexPath.row == 1) {
            GHCreateIssueTableViewController *createViewController = [[[GHCreateIssueTableViewController alloc] initWithRepository:self.repositoryString] autorelease];
            createViewController.delegate = self;
            
            UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:createViewController] autorelease];
            
            [self presentModalViewController:navController animated:YES];
        } else {
            GHAPIIssueV3 *issue = [self.issuesArray objectAtIndex:indexPath.row-2];
            GHViewIssueTableViewController *issueViewController = [[[GHViewIssueTableViewController alloc] 
                                                                    initWithRepository:self.repositoryString 
                                                                    issueNumber:issue.number]
                                                                   autorelease];
            [self.navigationController pushViewController:issueViewController animated:YES];
        }
    } else if (indexPath.section == kUITableViewSectionWatchingUsers) {
        // watched user
        GHAPIUserV3 *user = [self.watchedUsersArray objectAtIndex:indexPath.row-1];
        GHUserViewController *userViewController = [[[GHUserViewController alloc] initWithUsername:user.login] autorelease];
        [self.navigationController pushViewController:userViewController animated:YES];
        
    } else if (indexPath.section == kUITableViewSectionNetwork) {
        if (indexPath.row == 1) {
            // watch/unwatch
            if (_isWatchingRepository) {
                [GHAPIRepositoryV3 unwatchRepository:self.repositoryString 
                                   completionHandler:^(NSError *error) {
                                       if (error) {
                                           [self handleError:error];
                                       } else {
                                           _isWatchingRepository = NO;
                                           NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
                                           [set addIndex:kUITableViewSectionNetwork];
                                           [self.tableView reloadSections:set 
                                                         withRowAnimation:UITableViewRowAnimationNone];
                                       }                               }];
            } else {
                [GHAPIRepositoryV3 watchRepository:self.repositoryString 
                                 completionHandler:^(NSError *error) {
                                     if (error) {
                                         [self handleError:error];
                                     } else {
                                         _isWatchingRepository = YES;
                                         NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
                                         [set addIndex:kUITableViewSectionNetwork];
                                         [self.tableView reloadSections:set 
                                                       withRowAnimation:UITableViewRowAnimationNone];
                                     }
                                 }];
            }
        } else if (indexPath.row == 2) {
            [GHAPIRepositoryV3 forkRepository:self.repositoryString 
                               toOrganization:nil 
                            completionHandler:^(GHAPIRepositoryV3 *repository, NSError *error) {
                                if (error) {
                                    [self handleError:error];
                                } else {
                                    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Forked %@", @""), self.repositoryString] 
                                                                                     message:NSLocalizedString(@"You have successfully forked this Repository", @"") 
                                                                                    delegate:nil 
                                                                           cancelButtonTitle:nil 
                                                                           otherButtonTitles:NSLocalizedString(@"OK", @""), nil]
                                                          autorelease];
                                    [alert show];
                                }
                            }];
        } else if (indexPath.row == 3) {
            [GHAPIOrganizationV3 organizationsOfUser:[GHAuthenticationManager sharedInstance].username page:1 
                                   completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                                       
                                       self.organizations = array;
                                       
                                       if (self.organizations.count > 0) {
                                           if (self.organizations.count == 1) {
                                               // we only have one organization, act as if user select this only organization
                                               [self organizationsActionSheetDidSelectOrganizationAtIndex:0];
                                           } else {
                                               UIActionSheet *sheet = [[[UIActionSheet alloc] init] autorelease];
                                               
                                               [sheet setTitle:NSLocalizedString(@"Select an Organization", @"")];
                                               
                                               for (GHAPIOrganizationV3 *organization in self.organizations) {
                                                   [sheet addButtonWithTitle:organization.login];
                                               }
                                               
                                               [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
                                               sheet.cancelButtonIndex = sheet.numberOfButtons-1;
                                               
                                               sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                                               
                                               sheet.delegate = self;
                                               
                                               [sheet showInView:self.tabBarController.view];
                                           }
                                       } else {
                                           UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Organization Error", @"") 
                                                                                            message:NSLocalizedString(@"You are not part of any Organization!", @"") 
                                                                                           delegate:nil 
                                                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"") 
                                                                                  otherButtonTitles:nil]
                                                                 autorelease];
                                           [alert show];
                                       }
                                       
                                   }];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    } else if (indexPath.section == kUITableViewSectionAdministration) {
        if (indexPath.row == 1) {
            [GHRepository deleteTokenForRepository:self.repositoryString 
                             withCompletionHandler:^(NSString *deleteToken, NSError *error) {
                                 [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                                 if (error) {
                                     [self handleError:error];
                                 } else {
                                     self.deleteToken = deleteToken;
                                     
                                     UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Delete %@", @""), self.repositoryString] 
                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Are you absolutely sure that you want to delete %@? This action can't be undone!", @""), self.repositoryString] 
                                                                                     delegate:self 
                                                                            cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                                                            otherButtonTitles:NSLocalizedString(@"Delete", @""), nil]
                                                           autorelease];
                                     [alert show];
                                 }
                             }];
        }
    } else if (indexPath.section == kUITableViewSectionPullRequests) {
        GHPullRequestDiscussion *discussion = [self.pullRequests objectAtIndex:indexPath.row-1];
        
        NSString *repo = [NSString stringWithFormat:@"%@/%@", discussion.base.repository.owner, discussion.base.repository.name];
        
        GHViewIssueTableViewController *viewIssueViewController = [[[GHViewIssueTableViewController alloc] initWithRepository:repo issueNumber:discussion.number] autorelease];
        [self.navigationController pushViewController:viewIssueViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionRecentCommits) {
        GHAPIRepositoryBranchV3 *branch = [self.branches objectAtIndex:indexPath.row - 1];
        
        GHRecentCommitsViewController *recentViewController = [[[GHRecentCommitsViewController alloc] initWithRepository:self.repositoryString 
                                                                                                                  branch:branch.name]
                                                               autorelease];
        recentViewController.branchHash = branch.ID;
        [self.navigationController pushViewController:recentViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionBrowseBranches) {
        GHAPIRepositoryBranchV3 *branch = [self.branches objectAtIndex:indexPath.row - 1];
        
        GHViewRootDirectoryViewController *rootViewController = [[[GHViewRootDirectoryViewController alloc] initWithRepository:self.repositoryString
                                                                                                                        branch:branch.name
                                                                                                                          hash:branch.ID]
                                                                 autorelease];
        [self.navigationController pushViewController:rootViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionMilestones && indexPath.row > 0) {
        GHAPIMilestoneV3 *milestone = [self.milestones objectAtIndex:indexPath.row - 1];
        
        GHViewMilestoneViewController *milestoneViewController = [[[GHViewMilestoneViewController alloc] initWithRepository:self.repositoryString
                                                                                                            milestoneNumber:milestone.number]
                                                                  autorelease];
        [self.navigationController pushViewController:milestoneViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionLabels && indexPath.row > 0) {
        GHAPILabelV3 *label = [self.labels objectAtIndex:indexPath.row - 1];
        
        GHViewLabelViewController *labelViewController = [[[GHViewLabelViewController alloc] initWithRepository:self.repositoryString  
                                                                                                          label:label]
                                                          autorelease];
        [self.navigationController pushViewController:labelViewController animated:YES];
    } else if (indexPath.section == kUITableViewSectionCollaborators) {
        if (indexPath.row == 1) {
            // new collaborator
            
            OCPromptView *alert = [[[OCPromptView alloc] initWithPrompt:NSLocalizedString(@"Enter Username", @"") 
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                                      acceptButtonTitle:NSLocalizedString(@"OK", @"")]
                                   autorelease];
            alert.tag = kUIAlertViewAddCollaboratorTag;
            [alert show];
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        } else {
            GHAPIUserV3 *user = [self.collaborators objectAtIndex:indexPath.row - 2];
            
            GHUserViewController *userViewController = [[[GHUserViewController alloc] initWithUsername:user.login] autorelease];
            [self.navigationController pushViewController:userViewController animated:YES];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kUIAlertViewAddCollaboratorTag) {
        // new collaborator
        if (buttonIndex == 1) {
            // OK clicked
            OCPromptView *alert = (OCPromptView *)alertView;
            NSString *username = [alert enteredText];
            [GHAPIRepositoryV3 addCollaboratorNamed:username onRepository:self.repositoryString 
                                  completionHandler:^(NSError *error) {
                                      if (error) {
                                          [self handleError:error];
                                      } else {
                                          [self.tableView collapseSection:kUITableViewSectionCollaborators animated:NO];
                                          self.collaborators = nil;
                                          [self.tableView expandSection:kUITableViewSectionCollaborators animated:NO];
                                          UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added Collaborator", @"") 
                                                                                           message:[NSString stringWithFormat:NSLocalizedString(@"You have successfully added %@ as a Collaborator", @""), username] 
                                                                                          delegate:nil 
                                                                                 cancelButtonTitle:nil 
                                                                                 otherButtonTitles:NSLocalizedString(@"OK", @""), nil]
                                                                autorelease];
                                          [alert show];
                                      }
                                  }];
        }
    } else {
        if (buttonIndex == 1) {
            self.view.userInteractionEnabled = NO;
            [GHRepository deleteRepository:self.repositoryString 
                                 withToken:self.deleteToken 
                         completionHandler:^(NSError *error) {
                             if (error) {
                                 [self handleError:error];
                             } else {
                                 [self.delegate singleRepositoryViewControllerDidDeleteRepository:self];
                             }
                         }];
        }
    }
}

#pragma mark - height caching

- (void)cacheHeightForIssuesArray {
    NSInteger i = 2;
    for (GHAPIIssueV3 *issue in self.issuesArray) {
        [self cacheHeight:[self heightForDescription:issue.title]+50.0f forRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:kUITableViewSectionIssues] ];
        i++;
    }
}

- (void)cacheHeightForPullRequests {
    NSInteger i = 1;
    for (GHPullRequestDiscussion *discussion in self.pullRequests) {
        [self cacheHeight:[self heightForDescription:discussion.title]+50.0f forRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:kUITableViewSectionPullRequests] ];
        i++;
    }
}

#pragma mark - GHSingleRepositoryViewControllerDelegate

- (void)singleRepositoryViewControllerDidDeleteRepository:(GHSingleRepositoryViewController *)singleRepositoryViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - GHCreateIssueTableViewControllerDelegate

- (void)createIssueViewControllerDidCancel:(GHCreateIssueTableViewController *)createViewController {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)createIssueViewController:(GHCreateIssueTableViewController *)createViewController didCreateIssue:(GHAPIIssueV3 *)issue {
    self.issuesArray = nil;
    self.repository.openIssues = [NSNumber numberWithInt:[self.repository.openIssues intValue]+1 ];
    [self.tableView reloadData];
    [self.tableView expandSection:kUITableViewSectionIssues animated:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex < actionSheet.numberOfButtons - 1) {
        [self organizationsActionSheetDidSelectOrganizationAtIndex:buttonIndex];
    }
}

- (void)organizationsActionSheetDidSelectOrganizationAtIndex:(NSUInteger)index {
    GHAPIOrganizationV3 *organization = [self.organizations objectAtIndex:index];
    
    [GHAPIRepositoryV3 forkRepository:self.repositoryString 
                       toOrganization:organization.login 
                    completionHandler:^(GHAPIRepositoryV3 *repository, NSError *error) {
                        if (error) {
                            [self handleError:error];
                        } else {
                            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Forked %@", @""), self.repositoryString] 
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"You have successfully forked this Repository to Organization %@", @""), organization.login] 
                                                                            delegate:nil 
                                                                   cancelButtonTitle:nil 
                                                                   otherButtonTitles:NSLocalizedString(@"OK", @""), nil]
                                                  autorelease];
                            [alert show];
                        }
                    }];
}

@end
