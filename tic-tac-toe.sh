#!/bin/bash

clear

# get grid size from user
while [ -z $grid_size ] || [ $grid_size -lt 3 ] || [ $grid_size -gt 8 ]; do
    echo -n "ENTER GRID SIZE [3-8]: "
    read grid_size

    if [ $grid_size -lt 3 ]; then
    	echo "Size must be greater than 2!"
    elif [ $grid_size -gt 8 ]; then
        echo "Size must be lesser than 9!"
    fi
done

# set up starting values
declare -a final_score
final_score[1]=0 # score of player 1
final_score[2]=0 # score of player 2

is_exit_requested=false
is_set_finished=false
active_player=1 # player who gets the turn

grid_flags=()
for (( i=0; i<$((grid_size*grid_size)); i++ )) do
    grid_flags[$i]=0
done

# set up helper functions
function printBoard {
    for (( r=0; r<$grid_size; r++ )) do
        for (( c=0; c<$grid_size; c++ )) do
	    local index=$((r * grid_size + c))
            echo -n "${grid_flags[$index]} "
        done
    echo 
    done
}

function selectIndex {
    echo -n "ENTER GRID INDEX: "
    read selected_index
    if [[ $selected_index =~ ^-?[0-9]+$ ]]; then # check if integer
        local max_value=$(($grid_size * $grid_size - 1))
	if [ $selected_index -gt $max_value ]; then
            echo -e "MAXIMUM INDEX IS "$max_value"\n"
            selectIndex
        elif [ ${grid_flags[$selected_index]} -ne 0 ]; then  
            echo -e "SLOT IS ALREADY TAKEN \n" 
            selectIndex
        fi
    else 
        echo -e "YOU MUST PROVIDE A NUMBER! \n"
        selectIndex
    fi
}

function askToContinue {
    echo -n "DO YOU WANT TO PLAY ANOTHER SET? [Y/n] "
    read continue_playing
    continue_playing=$(echo $continue_playing | tr '[:upper:]' '[:lower:]')
    case "$continue_playing" in
        "y") is_exit_requested=false ;;
        "n") is_exit_requested=true ;;
        *) echo -e "\nINVALID ANSWER. PRINT 'Y/y' or 'N/n'"; askToContinue
    esac
}

# start game loop
while ! $is_exit_requested; do

    clear

    while ! $is_set_finished; do
        clear        
        printBoard
        
        echo -e "\nTURN OF PLAYER $active_player\n"
        selectIndex
        
        grid_flags[$selected_index]=$active_player

        (( active_player = active_player==1 ? 2 : 1 ))
    done

    askToContinue
done

