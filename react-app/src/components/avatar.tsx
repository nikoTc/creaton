import {Icon} from "../icons";
import clsx from 'clsx';

export const Avatar = ({src = '', size = 'large'}: any) => {
  const size_classes = {
    'large': 'w-32 h-32',
    'profile': 'w-20 h-20',
    'menu':'h-12 w-12',
    'small': 'w-8 h-8'
  }
  if (!src)
    return (
      <div className={clsx(size_classes[size], "rounded-full bg-gray-100 text-center")}>
        <Icon size={size === 'large' ? "5x" : undefined} className="m-auto text-gray-400 w-full h-full" name="question"/>
      </div>
    )
  else
    return (
      <img className={clsx(size_classes[size], "rounded-full", "border-2", "border-blue-primary", "object-cover")} src={src} alt="profile avatar"/>
    );
}
