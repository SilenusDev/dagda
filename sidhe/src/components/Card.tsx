import { Component, JSX, ParentProps } from 'solid-js';

interface CardProps extends ParentProps {
  title?: string;
  class?: string;
}

const Card: Component<CardProps> = (props) => {
  return (
    <div class={`bg-white rounded-lg shadow-md p-6 ${props.class || ''}`}>
      {props.title && (
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          {props.title}
        </h3>
      )}
      {props.children}
    </div>
  );
};

export default Card;
