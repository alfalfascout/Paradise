import { useState } from 'react';
import { Box, Button, DmIcon, Input, Section, Stack, Table, Tabs } from 'tgui-core/components';
import { createSearch, decodeHtmlEntities } from 'tgui-core/string';

import { useBackend } from '../../backend';

export const pda_cookbook = (props) => {
  const { act, data } = useBackend();
  const [tabIndex, setTabIndexInternal] = useState(data.tabIndex);
  const setTabIndex = (index) => {
    setTabIndexInternal(index);
    act('set_tab_index', { tab_index: index });
  };
  const decideTab = (index) => {
    switch (index) {
      case 0:
        return <CookbookIngredientsView />;
      case 1:
        return <CookbookRecipesView />;
      default:
        return "Invalid tab selected. If you see this, submit a bug report with exactly what you just did to get here.";
    }
  };

  return (
    <Stack fill vertical fillPositionedParent>
      <Stack.Item>
        <Tabs>
          <Tabs.Tab key="Ingredients" icon="carrot" selected={0 === tabIndex} onClick={() => setTabIndex(0)}>
            Ingredients
          </Tabs.Tab>
          <Tabs.Tab key="Recipes" icon="blender" selected={1 === tabIndex} onClick={() => setTabIndex(1)}>
            Recipes
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      
      {decideTab(tabIndex)}
    </Stack>
  );
};

export const CookbookIngredientsView = (props) => {
  const { act, data } = useBackend();
  const { ingredients, search_text } = data;
  
  const [ingredientsList, setIngredientsList] = useState(ingredients);
  const [searchText, setSearchText] = useState(search_text);
  
  return (
    <Section
      title="Ingredients"
      buttons={
        <Input
          width="200px"
          placeholder={`Search ingredients`}
          value={searchText}
          onChange={(value) => setSearchText(value)}
        />
      }
    >
      <Table m="0.5rem">
        <Table.Row header>
          <Table.Cell>Name</Table.Cell>
          <Table.Cell colspan="2">Stock</Table.Cell>
        </Table.Row>
        {ingredients
        .filter(
          createSearch(searchText, (ingredient) => {
            return ingredient;
          })
        )
        .sort((a, b) => a?.name.localeCompare(b?.name))
        .map((ingredient, i) => (
          <Table.Row key={i}>
            <Table.Cell>
              {ingredient}
            </Table.Cell>
            <Table.Cell>
              <NumberInput minValue="0" value={ingredients[ingredient]} />
            </Table.Cell>
            <Table.Cell>
              <Confirm icon="trash-alt" />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
   );
};

export const CookbookRecipesView = (props) => {
  const { act, data } = useBackend();
  const { categories, current_category, recipes, cookable_recipes, search_text } = data;

  const [recipeList, setRecipeList] = useState(recipes);
  const [cookableRecipeList, setCookableRecipeList] = useState(cookable_recipes);
  const [searchText, setSearchText] = useState(search_text);
  
  return (
    <Section>
      {categories.sort().map((category, i) => (
        <Button key={i} onClick={() => act('set_category', { name: category, search_text: searchText })}>
          {category}
        </Button>
      ))}
      {current_category && (
        <Section
          title={current_category}
          buttons={
            <Input
              width="200px"
              placeholder={`Search ${current_category}`}
              value={searchText}
              onChange={(value) => setSearchText(value)}
            />
          }
        >
          <Stack vertical>
            {recipes
              .filter(
                createSearch(searchText, (recipe) => {
                  return recipe.name + '|' + recipe.container + '|' + recipe.instructions.toString();
                })
              )
              .sort((a, b) => a?.name.localeCompare(b?.name))
              .map((recipe, i) => (
                <Stack.Item key={i}>
                  <Section title={decodeHtmlEntities(recipe.name)}>
                    <Stack>
                      <Stack.Item>
                        <DmIcon
                          icon={recipe.icon}
                          icon_state={recipe.icon_state}
                          style={{ width: '64px', height: '64px' }}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        {recipe.container}:
                        <ol>
                          {recipe.instructions.map((instruction, j) => (
                            <li key={`${i}-${j}`}>{instruction}</li>
                          ))}
                        </ol>
                      </Stack.Item>
                    </Stack>
                  </Section>
                </Stack.Item>
              ))}
          </Stack>
        </Section>
      )}
    </Section>
  );
};
