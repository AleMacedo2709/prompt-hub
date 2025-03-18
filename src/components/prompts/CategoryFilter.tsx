
import { useState } from "react";
import { Check, Filter } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Badge } from "@/components/ui/badge";

interface Category {
  id: string;
  name: string;
}

interface CategoryFilterProps {
  categories: Category[];
  selectedCategories: string[];
  onCategoryChange: (categories: string[]) => void;
}

const CategoryFilter = ({
  categories,
  selectedCategories,
  onCategoryChange,
}: CategoryFilterProps) => {
  const [isOpen, setIsOpen] = useState(false);

  const handleToggleCategory = (categoryId: string) => {
    if (selectedCategories.includes(categoryId)) {
      onCategoryChange(selectedCategories.filter((id) => id !== categoryId));
    } else {
      onCategoryChange([...selectedCategories, categoryId]);
    }
  };

  const clearFilters = () => {
    onCategoryChange([]);
  };

  return (
    <div className="mb-6 flex flex-wrap items-center gap-2">
      <DropdownMenu open={isOpen} onOpenChange={setIsOpen}>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" className="flex items-center gap-1">
            <Filter className="h-4 w-4" />
            <span>Filtrar por categoria</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="start" className="w-56">
          <DropdownMenuLabel>Categorias</DropdownMenuLabel>
          <DropdownMenuSeparator />
          {categories.map((category) => (
            <DropdownMenuCheckboxItem
              key={category.id}
              checked={selectedCategories.includes(category.id)}
              onCheckedChange={() => handleToggleCategory(category.id)}
            >
              {category.name}
            </DropdownMenuCheckboxItem>
          ))}
          {selectedCategories.length > 0 && (
            <>
              <DropdownMenuSeparator />
              <div className="px-2 py-1.5">
                <Button
                  variant="ghost"
                  size="sm"
                  className="w-full text-xs"
                  onClick={clearFilters}
                >
                  Limpar filtros
                </Button>
              </div>
            </>
          )}
        </DropdownMenuContent>
      </DropdownMenu>

      {selectedCategories.length > 0 && (
        <>
          <div className="flex flex-wrap gap-1">
            {selectedCategories.map((categoryId) => {
              const category = categories.find((c) => c.id === categoryId);
              return (
                <Badge
                  key={categoryId}
                  variant="secondary"
                  className="flex items-center gap-1 pl-2 bg-mp-light text-mp-primary"
                >
                  {category?.name}
                  <button
                    onClick={() => handleToggleCategory(categoryId)}
                    className="ml-1 rounded-full hover:bg-mp-primary/10 p-0.5"
                  >
                    <Check className="h-3 w-3" />
                  </button>
                </Badge>
              );
            })}
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="text-xs text-gray-500"
            onClick={clearFilters}
          >
            Limpar filtros
          </Button>
        </>
      )}
    </div>
  );
};

export default CategoryFilter;
