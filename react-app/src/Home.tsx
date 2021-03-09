import {gql, useQuery} from "@apollo/client";
import React, {CSSProperties} from "react";
import {Link} from "react-router-dom";

const CREATORS_QUERY = gql`
  query {
  creators(orderBy: timestamp, orderDirection: desc, first: 10) {
    id
    user
    creatorContract
    description
    subscriptionPrice
    timestamp
  }
}
`;

function Home() {
  const {loading, error, data} = useQuery(CREATORS_QUERY);
  // if (loading) return (<p>Loading...</p>);
  // if (error) return (<p>Error :(</p>);
  return (<div>
    <section className="bg-gradient-to-b from-blue-600 via-teal-400 to-teal-400 text-gray-700 body-font"><div className="container flex flex-col items-center px-5 py-16 mx-auto lg:px-20 lg:py-24 md:flex-row"><div className="w-5/6 lg:w-75 md:w-1/2 md:hidden"><img className="object-cover object-center rounded-lg" alt="hero" src="images/creatorcommunity.png" /></div> 
        <div className="flex flex-col items-center w-full pt-0 mb-16 text-left lg:flex-grow md:w-1/2 lg:pr-24 md:pr-16 md:items-start md:text-left md:mb-0 lg:text-center"><h1 className="mb-8 text-2xl font-bold tracking-tighter text-center text-blue-800 lg:text-left lg:text-5xl title-font">Create exclusive content for subscribers.</h1> 
          <div className="flex flex-wrap -mx-4 -mt-4 -mb-10 sm:-m-4 "><div className="flex flex-col items-center p-4 mb-6 text-center md:w-1/2 md:mb-0 lg:text-left lg:items-start"><div className="inline-flex items-center justify-center flex-shrink-0 w-12 h-12 mb-5 text-blue-800 bg-gray-200 rounded-full"><i className="fab fa-ethereum"></i></div> 
              <div className="flex-grow"><h2 className="mb-3 text-lg font-medium tracking-tighter text-gray-800 title-font">Earn Crypto Income</h2> 
                <p className="text-base leading-relaxed">Earn subscription income for <br /> creating exclusive content</p> 
                
                <a className="inline-flex items-center font-semibold text-blue-700 md:mb-2 lg:mb-0 hover:text-blue-400 hidden">Learn More
                  <svg className="w-4 h-4 ml-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path fill="none" d="M0 0h24v24H0z"></path><path d="M16.172 11l-5.364-5.364 1.414-1.414L20 12l-7.778 7.778-1.414-1.414L16.172 13H4v-2z"></path></svg></a></div></div> 
            <div className="flex flex-col items-center p-4 mb-6 text-center md:w-1/2 md:mb-0 lg:text-left lg:items-start"><div className="inline-flex items-center justify-center flex-shrink-0 w-12 h-12 mb-5 text-blue-800 bg-gray-200 rounded-full"><i className="fas fa-coins"></i></div> 
              <div className="flex-grow"><h2 className="mb-3 text-lg font-medium tracking-tighter text-gray-800 title-font">Tokenize your career</h2> 
                <p className="text-base leading-relaxed">Launch your own Creator Token</p> 
                
                <a className="inline-flex items-center font-semibold text-blue-700 md:mb-2 lg:mb-0 hover:text-blue-400 hidden">Learn More
                  <svg className="w-4 h-4 ml-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path fill="none" d="M0 0h24v24H0z"></path><path d="M16.172 11l-5.364-5.364 1.414-1.414L20 12l-7.778 7.778-1.414-1.414L16.172 13H4v-2z"></path></svg></a></div></div></div></div> 
        <div className="w-5/6 lg:w-75 md:w-1/2"><img className="object-cover object-center rounded-lg hidden md:block" alt="hero" src="images/creatorcommunity.png" /></div></div></section>
  
        {/* {data.creators.map((creator: any) => (
      <div key={creator.id}>
        <p>
          <Link to={"/creator/" + creator.creatorContract}>{creator.description} with price {creator.subscriptionPrice}</Link>
        </p>
      </div>
    ))} */}

    <div className="flex space-x-4 ">
      <div className="border-2 rounded-3xl border-gray-300 p-5 w-1/3 bg-white">

        <div className="flex justify-between">
          <img />

          <div>

          </div>
        </div>


        <img src="https://picsum.photos/293" className="mx-auto mb-6 w-full rounded-2xl" alt=""/>

        <h4 className="font-bold">MrCartographer</h4>
        <h5>Subsribe for <a href="#">$2500</a></h5>

      </div>

      <div className="border-2 rounded-3xl border-gray-300 p-5 w-1/3 bg-white">

<div className="flex justify-between">
  <img />

  <div>

  </div>
</div>


<img src="https://picsum.photos/293" className="mx-auto mb-6 w-full rounded-2xl" alt=""/>

<h4 className="font-bold">MrCartographer</h4>
<h5>Subsribe for <a href="#">$2500</a></h5>

</div>

<div className="border-2 rounded-3xl border-gray-300 p-5 w-1/3 bg-white">

<div className="flex justify-between">
  <img />

  <div>

  </div>
</div>


<img src="https://picsum.photos/293" className="mx-auto mb-6 w-full rounded-2xl" alt=""/>

<h4 className="font-bold">MrCartographer</h4>
<h5>Subsribe for <a href="#">$2500</a></h5>

</div>
    </div>  
  </div>);
}

export {CREATORS_QUERY};
export default Home;
