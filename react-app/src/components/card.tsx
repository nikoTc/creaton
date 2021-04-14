import {ButtonHTMLAttributes, FC, useState} from "react";
import {Icon} from "../icons";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
    className?: string;
    price?: number;
    name?: string;
    imgUrl?: string;
}

export const Card: FC<ButtonProps> = ({ className,price,name,imgUrl}) => {
    const [like, setLike] = useState(false);
    return (
        <div className="mt-12 max-w-lg mx-auto grid gap-5 lg:grid-cols-3 lg:max-w-none">
            <div className="flex flex-col rounded-2xl border p-8 overflow-hidden">
                <div className="flex-1 bg-white flex flex-col justify-between">
                    <div className="flex items-center justify-between">
                        <div className="flex-shrink-0">
                            <a href="#">
                                <img className="h-8 w-8 rounded-full"
                                     src="https://images.unsplash.com/photo-1527538079466-b6297ad15363?ixlib=rb-1.2.1&ixqx=giK1HBp0xK&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                                     alt="" />
                            </a>
                        </div>
                        <div>
                            <Icon onClick={() => setLike(!like)} name="heart" className={clsx('cursor-pointer',like ? 'text-red-500' : 'text-grey-dark')} />
                            <Icon name="ellipsis-h" className="text-grey-dark" />
                        </div>
                    </div>
                </div>

              {imgUrl && <div className="flex-shrink-0 my-6">
                <img className="h-72 w-72 w-full object-cover rounded-xl"
                     src={imgUrl}
                     alt=""/>
              </div>}
                <div>
                    <h4 className="text-lg font-semibold text-gray-900">
                      {name}
                    </h4>
                  {price && <div>
                        <span className="text-xs">
                            Subscribe for
                        </span>
                        <span className="font-semibold text-blue ml-2">
                            ${price} / month
                        </span>
                    </div>}
                </div>
            </div>
        </div>
    )
};
