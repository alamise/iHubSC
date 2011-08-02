//
//  GHPTeamViewController.m
//  iGithub
//
//  Created by Oliver Letterer on 11.07.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHPTeamViewController.h"
#import "GHPUserTableViewCell.h"
#import "GHPRepositoryTableViewCell.h"
#import "GHPUserViewController.h"
#import "GHPRepositoryViewController.h"

#define kUITableViewSectionMembers 0
#define kUITableViewSectionRepositories 1

@implementation GHPTeamViewController
@synthesize team=_team, teamID=_teamID, members=_members, repositories=_repositories, organization=_organization;

- (void)setTeamID:(NSNumber *)teamID {
    _teamID = [teamID copy];
    
    [GHAPITeamV3 teamByID:_teamID 
        completionHandler:^(GHAPITeamV3 *team, NSError *error) {
            if (error) {
                [self handleError:error];
            } else {
                self.team = team;
                self.title = self.team.name;
                if (self.isViewLoaded) {
                    [self.tableView reloadData];
                }
            }
        }];
}

#pragma mark - Initialization

- (id)initWithTeamID:(NSNumber *)teamID organization:(NSString *)organization {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        // Custom initialization
        self.teamID = teamID;
        self.organization = organization;
    }
    return self;
}

#pragma mark - Memory management


#pragma mark - UIExpandableTableViewDatasource

- (BOOL)tableView:(UIExpandableTableView *)tableView canExpandSection:(NSInteger)section {
    return section == kUITableViewSectionMembers || section == kUITableViewSectionRepositories;
}

- (BOOL)tableView:(UIExpandableTableView *)tableView needsToDownloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionMembers) {
        return self.members == nil;
    } else if (section == kUITableViewSectionRepositories) {
        return self.repositories == nil;
    }
    return NO;
}

- (UITableViewCell<UIExpandingTableViewCell> *)tableView:(UIExpandableTableView *)tableView expandingCellForSection:(NSInteger)section {
    GHPCollapsingAndSpinningTableViewCell *cell = [self defaultPadCollapsingAndSpinningTableViewCellForSection:section];
    
    if (section == kUITableViewSectionMembers) {
        cell.textLabel.text = NSLocalizedString(@"Members", @"");
    } else if (section == kUITableViewSectionRepositories) {
        cell.textLabel.text = NSLocalizedString(@"Repositories", @"");
    }
    
    return cell;
}

#pragma mark - pagination

- (void)downloadDataForPage:(NSUInteger)page inSection:(NSUInteger)section {
    if (section == kUITableViewSectionMembers) {
        [GHAPITeamV3 membersOfTeamByID:self.teamID page:1 
                     completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                         if (error) {
                             [self handleError:error];
                         } else {
                             [self.members addObjectsFromArray:array];
                             [self setNextPage:nextPage forSection:section];
                             [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] 
                                           withRowAnimation:UITableViewRowAnimationAutomatic];
                         }
                     }];
    } else if (section == kUITableViewSectionRepositories) {
        [GHAPITeamV3 repositoriesOfTeamByID:self.teamID page:page 
                          completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                              if (error) {
                                  [self handleError:error];
                              } else {
                                  [self.repositories addObjectsFromArray:array];
                                  [self setNextPage:nextPage forSection:section];
                                  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] 
                                                withRowAnimation:UITableViewRowAnimationAutomatic];
                              }
                          }];
    }
}

#pragma mark - UIExpandableTableViewDelegate

- (void)tableView:(UIExpandableTableView *)tableView downloadDataForExpandableSection:(NSInteger)section {
    if (section == kUITableViewSectionMembers) {
        [GHAPITeamV3 membersOfTeamByID:self.teamID page:1 
                     completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                         if (error) {
                             [self handleError:error];
                             [tableView cancelDownloadInSection:section];
                         } else {
                             self.members = array;
                             [self setNextPage:nextPage forSection:section];
                             [tableView expandSection:section animated:YES];
                         }
                     }];
    } else if (section == kUITableViewSectionRepositories) {
        [GHAPITeamV3 repositoriesOfTeamByID:self.teamID page:1 
                          completionHandler:^(NSMutableArray *array, NSUInteger nextPage, NSError *error) {
                              if (error) {
                                  [self handleError:error];
                                  [tableView cancelDownloadInSection:section];
                              } else {
                                  self.repositories = array;
                                  [self setNextPage:nextPage forSection:section];
                                  [tableView expandSection:section animated:YES];
                              }
                          }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.team) {
        return 0;
    }
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kUITableViewSectionMembers) {
        return self.members.count + 1;
    } else if (section == kUITableViewSectionRepositories) {
        return self.repositories.count + 1;
    }
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionMembers) {
        static NSString *CellIdentifier = @"GHPUserTableViewCell";
        
        GHPUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[GHPUserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [self setupDefaultTableViewCell:cell forRowAtIndexPath:indexPath];
        
        GHAPIUserV3 *user = [self.members objectAtIndex:indexPath.row - 1];
        
        cell.textLabel.text = user.login;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self updateImageView:cell.imageView atIndexPath:indexPath withAvatarURLString:user.avatarURL];
        
        return cell;
    } else if (indexPath.section == kUITableViewSectionRepositories) {
        static NSString *CellIdentifier = @"GHPRepositoryTableViewCell";
        
        GHPRepositoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[GHPRepositoryTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        [self setupDefaultTableViewCell:cell forRowAtIndexPath:indexPath];
        
        GHAPIRepositoryV3 *repository = [self.repositories objectAtIndex:indexPath.row-1];
        
        cell.textLabel.text = repository.fullRepositoryName;
        cell.detailTextLabel.text = repository.description;
        
        if ([repository.private boolValue]) {
            cell.imageView.image = [UIImage imageNamed:@"GHPrivateRepositoryIcon.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"GHPublicRepositoryIcon.png"];
        }
        
        return cell;
    }
    
    return self.dummyCell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kUITableViewSectionRepositories && indexPath.row > 0) {
        GHAPIRepositoryV3 *repository = [self.repositories objectAtIndex:indexPath.row-1];
        return [GHPRepositoryTableViewCell heightWithContent:repository.description];
    } else if (indexPath.section == kUITableViewSectionMembers && indexPath.row > 0) {
        return GHPUserTableViewCellHeight;
    }
    
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController = nil;
    
    if (indexPath.section == kUITableViewSectionMembers && indexPath.row > 0) {
        GHAPIUserV3 *user = [self.members objectAtIndex:indexPath.row - 1];
        
        viewController = [[GHPUserViewController alloc] initWithUsername:user.login];
    } else if (indexPath.section == kUITableViewSectionRepositories && indexPath.row > 0) {
        
        GHAPIRepositoryV3 *repo = [self.repositories objectAtIndex:indexPath.row-1];
        
        viewController = [[GHPRepositoryViewController alloc] initWithRepositoryString:repo.fullRepositoryName];
    }
    
    if (viewController) {
        [self.advancedNavigationController pushViewController:viewController afterViewController:self animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Keyed Archiving

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_team forKey:@"team"];
    [encoder encodeObject:_teamID forKey:@"teamID"];
    [encoder encodeObject:_members forKey:@"members"];
    [encoder encodeObject:_repositories forKey:@"repositories"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        _team = [decoder decodeObjectForKey:@"team"];
        _teamID = [decoder decodeObjectForKey:@"teamID"];
        _members = [decoder decodeObjectForKey:@"members"];
        _repositories = [decoder decodeObjectForKey:@"repositories"];
    }
    return self;
}

@end