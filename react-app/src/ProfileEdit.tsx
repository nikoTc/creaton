import {Button} from "./elements/button";
import React, {useContext, useEffect, useState} from "react";
import {Input} from "./elements/input";
import {Contract} from "ethers";
import creaton_contracts from "./Contracts";
import {useWeb3React} from "@web3-react/core";
import {Web3Provider} from "@ethersproject/providers";
import {useCurrentCreator, useCurrentProfile} from "./Utils";
import {Avatar} from "./components/avatar";
import {ARWEAVE_GATEWAY, ARWEAVE_URI} from "./Config";
import {NotificationHandlerContext} from "./ErrorHandler";
import {Web3UtilsContext} from "./Web3Utils";

const ProfileEdit = (props) => {
  const web3Context = useWeb3React<Web3Provider>()
  const fileInput = React.createRef<any>();
  const coverInput = React.createRef<any>();
  const [previewSrc, setPreviewSrc] = useState<any>('')
  const [coverSrc, setCoverSrc] = useState<any>('')
  const [username, setUsername] = useState<string>('')
  const [currentFile, setCurrentFile] = useState<File | undefined>(undefined)
  const [currentCoverFile, setCurrentCoverFile] = useState<File | undefined>(undefined)
  const {currentProfile, refetch} = useCurrentProfile()
  const {currentCreator} = useCurrentCreator()
  const notificationHandler = useContext(NotificationHandlerContext)
  const web3utils = useContext(Web3UtilsContext)

  useEffect(() => {
    console.log(currentProfile)
    if (currentProfile) {
      setUsername(currentProfile.username)
      if (currentProfile.image)
        setPreviewSrc(currentProfile.image)
      if (currentProfile.cover)
        setCoverSrc(currentProfile.cover)
    } else {
      setUsername('')
      setPreviewSrc('')
      setCoverSrc('')
    }
  }, [currentProfile])

  const showPreviewImage = (file, setSrc) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (e) {
      setSrc(e.target!.result)
    };
    reader.readAsDataURL(file);
  }

  const handleFileSelection = (event) => {
    const file = event.currentTarget.files[0];
    setCurrentFile(file)
    showPreviewImage(file, setPreviewSrc)
  };
  const handleCoverSelection = (event) => {
    const file = event.currentTarget.files[0];
    setCurrentCoverFile(file)
    showPreviewImage(file, setCoverSrc)
  };
  const CreatonAdminContract = creaton_contracts.CreatonAdmin
  const creatorFactoryContract = new Contract(CreatonAdminContract.address, CreatonAdminContract.abi)

  async function updateProfile(event) {
    event.preventDefault()
    const payload = {
      'username': username
    }
    if (currentFile) {
      const buf = await currentFile.arrayBuffer();
      const bytes = new Uint8Array(buf);
      const file_type = currentFile.type
      const formData = new FormData();
      formData.append("file", new Blob([bytes], {
        type: file_type
      }));
      const response = await fetch(ARWEAVE_URI + '/upload', {
        method: 'POST',
        body: formData
      })
      const arweave_id = await response.text()
      payload['image'] = ARWEAVE_GATEWAY + arweave_id
    } else if (previewSrc) {
      payload['image'] = previewSrc
    }
    if (currentCoverFile) {
      const buf = await currentCoverFile.arrayBuffer();
      const bytes = new Uint8Array(buf);
      const file_type = currentCoverFile.type
      const formData = new FormData();
      formData.append("file", new Blob([bytes], {
        type: file_type
      }));
      const response = await fetch(ARWEAVE_URI + '/upload', {
        method: 'POST',
        body: formData
      })
      const arweave_id = await response.text()
      payload['cover'] = ARWEAVE_GATEWAY + arweave_id
    } else if (coverSrc) {
      payload['cover'] = previewSrc
    }
    const {library} = web3Context;
    console.log(payload)
    const connectedContract = creatorFactoryContract.connect(library!.getSigner())
    let result
    try {
      result = await connectedContract.updateProfile(JSON.stringify(payload))
    } catch (error) {
      notificationHandler.setNotification({
        description: 'Could not create your profile' + error.message,
        type: 'error'
      });
      return;
    }
    web3utils.setIsWaiting(true);
    await result.wait(1)
    web3utils.setIsWaiting(false);
    notificationHandler.setNotification({description: 'Profile successfully updated', type: 'success'})
    refetch()
  }

  if (!web3Context.library)
    return (<div>Connect your wallet</div>)
  return (
    <form onSubmit={updateProfile} className="grid grid-cols-1 place-items-center">

      <input id="file" style={{display: 'none'}} accept="image/x-png,image/gif,image/jpeg"
             onChange={(event) => handleFileSelection(event)} name="file"
             type="file" ref={fileInput}/>

      <input id="file" style={{display: 'none'}} accept="image/x-png,image/gif,image/jpeg"
             onChange={(event) => handleCoverSelection(event)} name="file"
             type="file" ref={coverInput}/>
      <div className="flex flex-row">
        <div className="flex-shrink place-self-center p-5">
          <Button label="Upload Avatar" type="button" onClick={() => fileInput.current.click()}/>
        </div>
        <div className="p-5">
          <Avatar src={previewSrc}/>
        </div>
      </div>
      {currentCreator && (<div className="flex flex-col">
        <div className="flex-shrink place-self-center p-5">
          <Button label="Upload Cover Photo" type="button" onClick={() => coverInput.current.click()}/>
        </div>
        <div className="p-5 max-w-md h-10 overflow-hidden">
          <div className="max-h-full transform translate-y-1/2">
          <img className="transform -translate-y-1/2" src={coverSrc}/>
          </div>
        </div>
      </div>)}


      <div className="p-5"><Input type="text" name="username" placeholder="Your Username" label="Enter your username" value={username}
                                  onChange={(event) => {
                                    setUsername(event.target.value)
                                  }}/></div>
      <div><Button type="submit" label={currentProfile ? "Update Profile" : "Sign Up"}/></div>
    </form>)
}

export {ProfileEdit}
