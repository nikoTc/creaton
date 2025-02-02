import {gql, useQuery} from "@apollo/client";
import React, {useEffect} from "react";
import {Link} from "react-router-dom";
import {Card} from "./components/card";
import {FilterList} from "./components/filter-list";
import {useWeb3React} from "@web3-react/core";
import {Web3Provider} from "@ethersproject/providers";


const CREATORS_QUERY = gql`
  query {
  creators(orderBy: timestamp, orderDirection: desc) {
    id
    user
    creatorContract
    description
    subscriptionPrice
    timestamp
    subscribers {
      id
      status
      user
    }
    profile {
      data
    }
  }
}
`;

function Creators() {
  const {loading, error, data} = useQuery(CREATORS_QUERY, {pollInterval: 10000});
  const {account} = useWeb3React<Web3Provider>()
  if (loading) return (<p>Loading...</p>);
  if (error) return (<p>Error :(</p>);
  const items = data.creators.map((creator: any) => {
    let subtitle = '$' + creator.subscriptionPrice + ' / month'
    if(account){
      const found = creator.subscribers.find(element => element.user.toLowerCase() === account.toLowerCase());
      if(found) {
        if(found.status==='requested_subscribe')
          subtitle="Subscription Requested"
        if(found.status==='pending_subscribe')
          subtitle="Access Granted. Start streaming for " + subtitle
      }
    }
    return {
      avatar: JSON.parse(creator.profile.data).image,
      title: JSON.parse(creator.profile.data).username,
      subtitle: subtitle,
      description: creator.description,
      count: creator.subscribers.length,
      source: 'subscribers',
      url: "/creator/" + creator.creatorContract
    }
  })
  return (<FilterList list={items}/>);
}

export {CREATORS_QUERY};
export default Creators;
