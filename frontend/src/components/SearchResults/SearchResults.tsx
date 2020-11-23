import React from 'react';
import * as Icon from 'react-feather';
import {
  SearchResponse,
  SearchResult,
  RelatedFile,
  InfoBoxType,
  Session,
} from '../../api/types';
import {SearchHit} from './SearchHit';
import {SearchState} from './SearchState';
import {Loading} from '../visus/Loading/Loading';
import {HitInfoBox} from './HitInfoBox';
import {SearchQuery} from '../../api/rest';
import './SearchResults.css';
import Pagination from './Pagination';
import {Pager} from './Pagination';

interface SearchResultsProps {
  searchQuery: SearchQuery;
  searchState: SearchState;
  searchResponse?: SearchResponse;
  session?: Session;
  onSearchRelated: (relatedFile: RelatedFile) => void;
}

interface SearchResultsState {
  selectedHit?: SearchResult;
  selectedInfoBoxType: InfoBoxType;
  pager?: Pager;
  updateScroll: boolean;
}

class SearchResults extends React.PureComponent<
  SearchResultsProps,
  SearchResultsState
> {
  lastSearchResponse?: SearchResponse;
  private divRef: React.RefObject<HTMLDivElement>;
  constructor(props: SearchResultsProps) {
    super(props);
    this.state = {
      selectedInfoBoxType: InfoBoxType.DETAIL,
      updateScroll: false,
    };
    this.divRef = React.createRef<HTMLDivElement>();
    this.onChangePage = this.onChangePage.bind(this);
  }

  componentDidUpdate() {
    if (
      this.state.updateScroll &&
      this.state.pager &&
      this.props.searchResponse
    ) {
      this.setState({
        updateScroll: false,
        selectedHit: this.props.searchResponse.results[
          this.state.pager.startIndex
        ],
      });
    }
    if (this.lastSearchResponse !== this.props.searchResponse) {
      this.setState({
        selectedHit: this.props.searchResponse
          ? this.props.searchResponse.results[0]
          : undefined,
        selectedInfoBoxType: InfoBoxType.DETAIL,
      });
    }
    this.lastSearchResponse = this.props.searchResponse;
  }

  renderSearchHits(
    currentHits: SearchResult[],
    selectedHit?: SearchResult,
    session?: Session
  ) {
    return (
      <div className="search-hits-group">
        {currentHits.map((hit, idx) => (
          <SearchHit
            hit={hit}
            key={idx}
            selectedHit={
              selectedHit &&
              hit.id === selectedHit.id &&
              hit.augmentation?.type === selectedHit.augmentation?.type
                ? true
                : false
            }
            session={session}
            onSearchHitExpand={hit =>
              this.setState({
                selectedHit: hit,
                selectedInfoBoxType: InfoBoxType.DETAIL,
              })
            }
            onSearchRelated={this.props.onSearchRelated}
            onAugmentationOptions={hit =>
              this.setState({
                selectedHit: hit,
                selectedInfoBoxType: InfoBoxType.AUGMENTATION,
              })
            }
          />
        ))}
      </div>
    );
  }

  onChangePage(pager: Pager) {
    this.setState({pager: pager, updateScroll: true});
    if (this.divRef.current) {
      this.divRef.current.scrollTo({
        top: 0,
        behavior: 'smooth',
      });
    }
  }

  render() {
    const {searchResponse, searchState, searchQuery, session} = this.props;
    const centeredDiv: React.CSSProperties = {
      width: 820,
      textAlign: 'center',
      marginTop: '1rem',
    };
    switch (searchState) {
      case SearchState.SEARCH_REQUESTING: {
        return (
          <div style={centeredDiv}>
            <Loading message="Searching..." />
          </div>
        );
      }
      case SearchState.SEARCH_FAILED: {
        return (
          <div style={centeredDiv}>
            <Icon.XCircle className="feather" />
            &nbsp; An unexpected error occurred. Please try again later.
          </div>
        );
      }
      case SearchState.SEARCH_SUCCESS: {
        if (!(searchResponse && searchResponse.results.length > 0)) {
          return (
            <div style={centeredDiv}>
              <Icon.AlertCircle className="feather text-primary" />
              &nbsp;No datasets found, please try another query.
            </div>
          );
        }

        const {selectedHit, selectedInfoBoxType, pager} = this.state;

        const pageSize = 19; // total number of items that will be displayed
        const startIdx = pager ? pager.startIndex : 0;
        const lastIdx = pager ? pager.endIndex + 1 : pageSize;
        const currentHits = searchResponse.results.slice(startIdx, lastIdx);

        return (
          <div className="d-flex flex-row container-vh-full pt-1">
            <div
              ref={this.divRef}
              className="container-vh-scroll column-search-hits"
            >
              {this.renderSearchHits(currentHits, selectedHit, session)}
              <hr />
              <div className="container mt-2">
                <div className="text-center">
                  {
                    <Pagination
                      totalRows={searchResponse.results.length}
                      onChangePage={this.onChangePage}
                      pageSize={pageSize}
                    />
                  }
                </div>
              </div>
            </div>
            {selectedHit && (
              <div className="container-vh-scroll column-infobox">
                <HitInfoBox
                  hit={selectedHit}
                  searchQuery={searchQuery}
                  infoBoxType={selectedInfoBoxType}
                  session={session}
                />
              </div>
            )}
          </div>
        );
      }
      case SearchState.CLEAN:
      default: {
        return null;
      }
    }
  }
}

export {SearchResults};
