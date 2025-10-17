import React, { useState } from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory, selectRightInventoryCollapsed, toggleRightInventory } from '../../store/inventory';
import { Items } from '../../store/items';
import { craftItem } from '../../thunks/craftItem';
import { useAppDispatch } from '../../store';
import { setItemAmount } from '../../store/inventory';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faHammer, faCheck, faTimes, faChevronUp, faChevronDown } from '@fortawesome/free-solid-svg-icons';
import { getItemUrl } from '../../helpers';

const CraftingInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);
  const isCollapsed = useAppSelector(selectRightInventoryCollapsed);
  const itemAmount = useAppSelector((state) => state.inventory.itemAmount);
  const dispatch = useAppDispatch();
  const [selectedItem, setSelectedItem] = useState<number | null>(null);

  const hasIngredients = (item: any) => {
    if (!item.ingredients) return true;

    const ingredientEntries = Object.entries(item.ingredients);
    return ingredientEntries.every(([ingredientName, requiredAmount]) => {
      const playerItem = leftInventory.items.find((playerItem) => playerItem.name === ingredientName);
      const required = requiredAmount as number;

      const isPercentage = required < 1 && required > 0;

      if (isPercentage) {
        const durability = playerItem?.metadata?.durability || 0;
        return durability >= required * 100;
      } else {
        return playerItem && (playerItem.count || 0) >= required;
      }
    });
  };

  const getAvailableIngredients = (item: any) => {
    if (!item.ingredients) return [];

    const sortedIngredients = Object.entries(item.ingredients).sort(([, a], [, b]) => {
      const aIsPercentage = (a as number) < 1 && (a as number) > 0;
      const bIsPercentage = (b as number) < 1 && (b as number) > 0;

      if (aIsPercentage && !bIsPercentage) return -1;
      if (!aIsPercentage && bIsPercentage) return 1;
      return 0;
    });

    return sortedIngredients.map(([ingredientName, requiredAmount]) => {
      const playerItem = leftInventory.items.find((playerItem) => playerItem.name === ingredientName);
      const available = playerItem ? playerItem.count || 0 : 0;
      const required = requiredAmount as number;

      const isPercentage = required < 1 && required > 0;

      let displayRequired, displayAvailable, hasEnough;

      if (isPercentage) {
        const durability = playerItem?.metadata?.durability || 0;
        const durabilityPercent = Math.round(durability);
        displayRequired = `${(required * 100).toFixed(0)}%`;
        displayAvailable = `${durabilityPercent}%`;
        hasEnough = durability >= required * 100;
      } else {
        displayRequired = required.toString();
        displayAvailable = available.toString();
        hasEnough = available >= required;
      }

      return {
        name: ingredientName,
        required,
        available,
        displayRequired,
        displayAvailable,
        hasEnough,
        itemData: Items[ingredientName],
      };
    });
  };

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.valueAsNumber =
      isNaN(event.target.valueAsNumber) || event.target.valueAsNumber < 0 ? 0 : Math.floor(event.target.valueAsNumber);
    dispatch(setItemAmount(event.target.valueAsNumber));
  };

  const handleCraft = (item: any, slot: number) => {
    if (!hasIngredients(item)) return;

    const emptySlot = leftInventory.items.find((slot) => !slot.name);
    if (!emptySlot) {
      console.error('No empty slots in player inventory');
      return;
    }

    dispatch(
      craftItem({
        fromSlot: slot,
        fromType: rightInventory.type,
        toSlot: emptySlot.slot,
        toType: leftInventory.type,
        count: itemAmount || 1,
      })
    );
  };

  if (rightInventory.type !== 'crafting') return null;

  const collapseButton = (
    <button className="inventory-collapse-button" onClick={() => dispatch(toggleRightInventory())}>
      <FontAwesomeIcon icon={isCollapsed ? faChevronDown : faChevronUp} size="lg" />
    </button>
  );

  return (
    <div className={`inventory-grid-wrapper ${isCollapsed ? 'collapsed' : ''}`}>
      <div>
        <div className="inventory-grid-header-wrapper">
          <div className="inventory-header-content">
            <p>{rightInventory.label || 'Crafting'}</p>
            <div className="inventory-header-right">
              <input
                className="inventory-control-input"
                type="number"
                defaultValue={itemAmount}
                onChange={inputHandler}
                min={0}
                placeholder="Qty"
              />
              {collapseButton}
            </div>
          </div>
        </div>
      </div>
      <div className={`inventory-grid-container ${isCollapsed ? 'collapsed' : ''}`}>
        <div className="crafting-recipes">
          {rightInventory.items.map((item, index) => {
            if (!item.name) return null;

            const itemData = Items[item.name];
            const canCraft = hasIngredients(item);
            const ingredients = getAvailableIngredients(item);

            return (
              <div
                key={index}
                className={`crafting-recipe ${selectedItem === index ? 'selected' : ''} ${!canCraft ? 'disabled' : ''}`}
                onClick={() => setSelectedItem(selectedItem === index ? null : index)}
              >
                <div className="recipe-header">
                  <div className="recipe-item">
                    <img src={getItemUrl(item.name)} alt={item.name} className="recipe-item-image" />
                    <div className="recipe-item-info">
                      <h4>{itemData?.label || item.name}</h4>
                      <p className="recipe-description">{item.metadata?.description || ''}</p>
                      {(item as any).duration && (
                        <p className="recipe-duration">
                          <FontAwesomeIcon icon={faHammer} />
                          {(item as any).duration / 1000}s
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="recipe-actions">
                    {canCraft ? (
                      <button
                        className="craft-button"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleCraft(item, item.slot);
                        }}
                      >
                        <FontAwesomeIcon icon={faHammer} />
                        Craft
                      </button>
                    ) : (
                      <button className="craft-button disabled" disabled>
                        <FontAwesomeIcon icon={faTimes} />
                        Craft
                      </button>
                    )}
                  </div>
                </div>

                {selectedItem === index && (
                  <div className="recipe-ingredients">
                    <h5>Ingredients Required:</h5>
                    <div className="ingredients-list">
                      {ingredients.map((ingredient, idx) => (
                        <div key={idx} className={`ingredient-item ${ingredient.hasEnough ? 'available' : 'missing'}`}>
                          <img src={getItemUrl(ingredient.name)} alt={ingredient.name} className="ingredient-image" />
                          <div className="ingredient-info">
                            <span className="ingredient-name">{ingredient.itemData?.label || ingredient.name}</span>
                            <span className="ingredient-amount">
                              {ingredient.displayAvailable} / {ingredient.displayRequired}
                            </span>
                          </div>
                          <div className="ingredient-status">
                            {ingredient.hasEnough ? (
                              <FontAwesomeIcon icon={faCheck} className="status-check" />
                            ) : (
                              <FontAwesomeIcon icon={faTimes} className="status-cross" />
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default CraftingInventory;
