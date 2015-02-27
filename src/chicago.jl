Pkg.add("Dates")

using Dates

function read_in()
    #= For reading in the csv file to be used and parsing it=#
    # read the comma delimited file, here it is on my computer
    array1 = readdlm("/users/dataronin/documents/february2015/ms04334.csv",',')

    # cut out the headers
    array2 = array1[2:end,:]

    # separate into primet and vanmet
    is_primet = array2[:,3].=="PRIMET"
    primet_array = array2[is_primet.==true,:]
    vanmet_array = array2[is_primet.==false,:]

    #= 
    Indices of the various parts of wind file 
    Dates in column 8, mean wind direction 5 minutes in 13,
    std of wind direction in 15, mean ux vector in 17.
    std ux vector in 19, mean uy vector in 21,
    std uy vector in 23
    =#

    dat = 8
    res_mean = 9
    res_max = 11
    dir_mean = 13
    dir_std = 15
    wux_mean = 17
    wux_std = 19
    wuy_mean = 21
    wuy_std = 23
    temp_mean = 25
    temp_dev = 27

    # comprehend the dates
    d2_pri=[Dates.DateTime(x,"mm/dd/yyyy HH:MM:SS") for x in primet_array[:,dat]]
    d2_van=[Dates.DateTime(x,"mm/dd/yyyy HH:MM:SS") for x in vanmet_array[:,dat]]

    return primet_array, vanmet_array, d2_pri, d2_van, dat, dir_mean, dir_std, wux_mean, wux_std, wuy_mean, wuy_std, dat,
    res_mean, res_max, dir_mean, dir_std, wux-mean, wux_std, wuy_mean, wuy_std, temp_mean, temp_std
end


function date_to_dict(array_x, col, d2_x)
    #= create an empty dictionary, then key it on the date, without hhmm=#
    emptyDict = Dict()

    for index = 1:length(d2_x)

        # if the key is not in the dictionary, put it in and give value of that column
        if ! haskey(emptyDict, (year(d2_x[index]), month(d2_x[index]), day(d2_x[index])))
            emptyDict[(year(d2_x[index]), month(d2_x[index]), day(d2_x[index]))] = [array_x[index,col]]
        # if the key is in the dictionary, append the new value to the end of the existing array
        elseif haskey(emptyDict, (year(d2_x[index]), month(d2_x[index]), day(d2_x[index])))
            push!(emptyDict[(year(d2_x[index]), month(d2_x[index]), day(d2_x[index]))], array_x[index,col])
        end
    end

    return emptyDict
end

function establish_vects(array_x, wux_mean, wuy_mean, d2_x)
    #= Create the daily maps  
    for windspeed based on x and y 
    components=#

    wux_dict = date_to_dict(array_x, wux_mean, d2_x)
    wuy_dict = date_to_dict(array_x, wuy_mean, d2_x)

    return wux_dict, wuy_dict
end

function reduce_dicts(input)
    #= performs reductions on each input's list =#
    filled_d = [x=>reduce(+,input[x]) for x in keys(input)]
    return filled_d
end

function make_dicts_primet(primet_array, d2_pri)
    # = functions to process our specific data =#

    # windspeed flag
    flag_results_wspd_snc_pri = Dict()
    # windspeed max flag
    flag_results_wspd_snc_pri_max = Dict()
    # windmag flag
    flag_results_wmag_snc_pri = Dict()
    # wind dir flag
    flag_results_wdir_snc_pri = Dict()
    # wind dir std flag
    flag_results_wdir_snc_pri_std = Dict()
    # wux flag
    flag_results_wux_pri = Dict()
    # wuy flag
    flag_results_wuy_pri = Dict()
    # wux std flag
    flag_results_wux_pri_std = Dict()
    # wuy std flag
    flag_results_wuy_pri_std = Dict()
    # wtemp flag
    flag_results_temp_pri = Dict()
    # wtemp std flag
    flag_results_temp_pri_std = Dict()

    return flag_results_wspd_snc_pri, flag_results_wspd_snc_pri_max, flag_results_wmag_snc_pri, flag_results_wdir_snc_pri, 
        flag_results_wdir_snc_pri_std, flag_results_wux_pri, flag_results_wux_pri_std, flag_results_wuy_pri,
        flag_results_wuy_pri_std, flag_results_temp_pri, flag_results_temp_pri_std
end


function make_dicts_vanmet(vanmet_array, d2_van)
    # = functions to process our specific data =#

    # windspeed flag
    flag_results_wspd_snc_van = Dict()
    # windspeed max flag
    flag_results_wspd_snc_van_max = Dict()
    # wind mag flag
    flag_results_wmag_snc_van = Dict()
    # wind dir sonic flag
    flag_results_wdir_snc_van = Dict()
    # winddir sonic std
    flag_results_wdir_snc_van_std = Dict()
    # wux flag
    flag_results_wux_van = Dict()
    # wuy flag
    flag_results_wuy_van = Dict()
    # wux std
    flag_results_wux_van_std = Dict()
    # wuy std
    flag_results_wuy_van_std = Dict()
    # wtem flag
    flag_results_temp_van = Dict()
    # temp std flag
    flag_results_temp_van_std = Dict()

    return flag_results_wspd_snc_van, flag_results_wspd_snc_van_max, flag_results_wmag_snc_van, flag_results_wdir_snc_van, 
        flag_results_wdir_snc_van_std, flag_results_wux_van, flag_results_wux_van_std, flag_results_wuy_van,
        flag_results_wuy_van_std, flag_results_temp_van, flag_results_temp_van_std
end


function flags(flag_results, col, array_x, d2_x)
    #= runs the flagging algorithm on a column=#

    # Note: let the flag results dictate the values in the actual reasults.
    flag_dict = date_to_dict(array_x, col, d2_x)

    # total numner of values in flag dict
    rejected = [x=>length(flag_dict[x][flag_dict[x].=="M"].==true)/(length(flag_dict[x])-1) for x in keys(flag_dict)]
    questioned = [x=>length(flag_dict[x][flag_dict[x].=="Q"].==true)/(length(flag_dict[x])-1) for x in keys(flag_dict)]
    estimated = [x=>length(flag_dict[x][flag_dict[x].=="E"].==true)/(length(flag_dict[x])-1) for x in keys(flag_dict)]

    # implement flagging algorithm    
    for (k,v) in rejected
       if v >= 0.2
           flag_results[k]="M"
       elseif v < 0.2
           if questioned[k] + v > 0.05
               flag_results[k] ="Q"
           elseif estimated[k] > 0.05
               flag_results[k] = "E"
           elseif questioned[k] + estimated[k] + v < 0.05
               flag_results[k] = "A"
           else
               flag_results[k] = "H"
           end
       end
   end
   return flag_results    
end

function flags_resultant(ux_flag, uy_flag, dir_flag)
    #= if the ux, uy, or direction flag is missing, questionable, or estimated 
    then the resultant flag is also missing, questionable, or estimated =#

    if ux_flag == "M" || uy_flag == "M" || dir_flag == "M"
        res_flag = "M"

    elseif ux_flag == "Q" || uy_flag == "Q" || dir_flag == "Q"
        res_flag = "Q"

    elseif ux_flag == "E" || uy_flag == "E" || dir_flag == "E"
        res_flag = "E"

    else
        res_flag = "A"
    end
    # return the resultant flag which is a result of the component flags making it
    return res_flag
end

function flag_primet(primet_array, d2_pri)
    #= Magnitude is flagged in a latter part of the structure =#

    # create look ups for the results on primet
    flag_results_wspd_snc_pri, flag_results_wspd_snc_pri_max, flag_results_wmag_snc_pri, flag_results_wdir_snc_pri, 
        flag_results_wdir_snc_pri_std, flag_results_wux_pri, flag_results_wux_pri_std, flag_results_wuy_pri,
        flag_results_wuy_pri_std, flag_results_temp_pri, flag_results_temp_pri_std = make_dicts_primet(primet_array, d2_pri)

    # wind speed
    flag_results_wspd_snc_pri = flags(flag_results_wspd_snc_pri, 10, primet_array, d2_pri)
    # wind speed max
    flag_results_wspd_snc_pri_max = flags(flag_results_wspd_snc_pri_max, 12,  primet_array, d2_pri)
    # wind direction
    flag_results_wdir_snc_pri = flags(flag_results_wdir_snc_pri, 14,  primet_array, d2_pri)
    # wind direction std
    flag_results_wdir_snc_pri_std = flags(flag_results_wdir_snc_pri_std, 16,  primet_array, d2_pri)
    # ux vector flag
    flag_results_wux_pri = flags(flag_results_wux_pri, 18,  primet_array, d2_pri)
    # ux standard dev flag
    flag_results_wux_pri_std = flags(flag_results_wux_pri_std,20,  primet_array, d2_pri)
    # uy vector flag
    flag_results_wuy_pri = flags(flag_results_wuy_pri, 22,  primet_array, d2_pri)
    # uy standard dev flag
    flag_results_wuy_pri_std = flags(flag_results_wuy_pri_std, 24,  primet_array, d2_pri)
    # air temperature flag
    flag_results_temp_pri = flags(flag_results_temp_pri, 26,  primet_array, d2_pri)
    # air temperature standard dev flag
    flag_results_temp_pri_std = flags(flag_results_temp_pri_std, 28,  primet_array, d2_pri)

    # magnitude is M, E, or Q depending on if the ux, uy, or dir are M, E, or Q.
    flag_results_wmag_snc_pri = [x => flags_resultant(flag_results_wux_pri[x], flag_results_wuy_pri[x], flag_results_wdir_snc_pri[x]) for x in keys(flag_results_wux_pri)]

    return flag_results_wspd_snc_pri, flag_results_wspd_snc_pri_max, flag_results_wmag_snc_pri, flag_results_wdir_snc_pri, 
        flag_results_wdir_snc_pri_std, flag_results_wux_pri, flag_results_wux_pri_std, flag_results_wuy_pri,
        flag_results_wuy_pri_std, flag_results_temp_pri, flag_results_temp_pri_std
end

function flag_vanmet(vanmet_array, d2_van)
    #= Magnitude is not flagged here because it is not computed here =#

    flag_results_wspd_snc_van, flag_results_wspd_snc_van_max, flag_results_wmag_snc_van, flag_results_wdir_snc_van, 
        flag_results_wdir_snc_van_std, flag_results_wux_van, flag_results_wux_van_std, flag_results_wuy_van,
        flag_results_wuy_van_std, flag_results_temp_van, flag_results_temp_van_std = make_dicts_vanmet(vanmet_array, d2_van)

    # wind speed flag
    flag_results_wspd_snc_van = flags(flag_results_wspd_snc_van, 10, vanmet_array, d2_van)
    # max wind speed
    flag_results_wspd_snc_van_max = flags(flag_results_wspd_snc_van_max, 12, vanmet_array, d2_van)
    # wind direction flag
    flag_results_wdir_snc_van = flags(flag_results_wdir_snc_van, 14,  vanmet_array, d2_van)
    # wind direction std flag
    flag_results_wdir_snc_van_std = flags(flag_results_wdir_snc_van_std, 16,  vanmet_array, d2_van)
    # wux flag
    flag_results_wux_van = flags(flag_results_wux_van, 18,  vanmet_array, d2_van)
    # wux std flag
    flag_results_wux_van_std = flags(flag_results_wux_van_std,20,  vanmet_array, d2_van)
    # wuy flag
    flag_results_wuy_van = flags(flag_results_wuy_van, 22,  vanmet_array, d2_van)
    # wuy std flag
    flag_results_wuy_van_std = flags(flag_results_wuy_van_std, 24,  vanmet_array, d2_van)
    # temp flag
    flag_results_temp_van = flags(flag_results_temp_van, 26,  vanmet_array, d2_van)
    # temp std flag
    flag_results_temp_van_std = flags(flag_results_temp_van_std, 28,  vanmet_array, d2_van)

    # magnitude is M, E, or Q depending on if the ux, uy, or dir are M, E, or Q.
    flag_results_wmag_snc_van = [x => flags_resultant(flag_results_wux_van[x], flag_results_wuy_van[x], flag_results_wdir_snc_van[x]) for x in keys(flag_results_wux_van)]


    return flag_results_wspd_snc_van, flag_results_wspd_snc_van_max, flag_results_wmag_snc_van, flag_results_wdir_snc_van, 
        flag_results_wdir_snc_van_std, flag_results_wux_van, flag_results_wux_van_std, flag_results_wuy_van,
        flag_results_wuy_van_std, flag_results_temp_van, flag_results_temp_van_std
end

function windspeed(ux, uy)
    #= computes windspeed based on pythagorean theorem =#
    wspd = round(sqrt(ux^2 + uy^2)*100)/100
    return wspd
end

function winddirection(ux, uy)
    #= Because we have a Campbell logger we invert the uy component=#
    ux = ux
    uy = -uy

    if uy > 0
        # q1 and q2, and add 180 to go to cardinal direction
        output = (270-atan(ux/uy)*(360/(2*pi))+180)+180
    elseif uy < 0 
        # q3 and q4, and add 180 to go to cardinal direction
        output = (90-atan(ux/uy)*(360/(2*pi))+180)+180
    elseif uy == 0
        
        if ux > 0 
            output = 360
        elseif ux <= 0
            output = 0
        end

    return output
    end
end

function convention(output)
    #= The meteorological convention is 180 to 540 so we convert back =#
    if output > 360
        wdir = output - 360
    elseif output < 0
        wdir = output + 360
    else
        wdir = output
    end
    return wdir
end

function wind_iter(array_x, d2_x)

    #= 
    wux mean is the daily mean of all wux
    wuy mean is the daily mean of all wuy

    wux dev is the standard deviation of the mean 5 minute wux
    wuy dev is the standard deviation of the mean 5 minute wuy

    mean_wind is the mean of the five minute resultant winds

    max_gust is the max of the max five minute gusts

    wspd is the daily resultant

    wdir is the vector computed daily wind direction from the components
    wdirdev is the standard deviation on the vector computed wind direction
    =#

    # x and y vectors, as dictionaries, for like this d[(2013, 04, 10)] = [val, val, val, val, val, ...]
    wux_dict, wuy_dict = establish_vects(array_x, wux_mean, wuy_mean, d2_x)
    wux_flags = date_to_dict(array_x, wux_mean+1, d2_x)
    wuy_flags = date_to_dict(array_x, wuy_mean+1, d2_x)

    # maximum gust
    array_max = date_to_dict(array_x, res_max, d2_x)
    max_flags = date_to_dict(array_x, res_max + 1, d2_x)

    # mean speed
    array_mean = date_to_dict(array_x, res_mean, d2_x)
    mean_flags = date_to_dict(array_x, res_mean + 1, d2_x)

    # temperature
    array_temp = date_to_dict(array_x, temp_mean, d2_x)
    temp_flags = date_to_dict(array_x, temp_mean + 1, d2_x)

    # wind direction
    array_flux = date_to_dict(array_x, dir_mean, d2_x)
    flux_flags = date_to_dict(array_x, dir_mean+1, d2_x)

    # add all x and y vector for the day to get resultant along each axis, like this: d[(2013, 04, 10)] = [5.45]
    wux_sums = reduce_dicts(wux_dict)
    # of course there are two values for the day one for x and one for y
    wuy_sums = reduce_dicts(wuy_dict)


    # new way, to check for flags and not include the values associated with those flags!

    # wux_mean_day = [x=>mean(wux_dict[x]) for x in keys(wux_dict)]
    wux_mean_day= [x=>sum(wux_dict[x][wux_flags[x].!="M"])/length(wux_dict[x][wux_flags[x].!="M"]) for x in keys(wux_dict)]
    # filter out "infinite values" caused by divide by 0 errors
    # wux_mean_day[wux_mean_day.==Inf]=0

    # wuy_mean_day = [x=>mean(wuy_dict[x]) for x in keys(wuy_dict)]
    wuy_mean_day= [x=>sum(wuy_dict[x][wuy_flags[x].!="M"])/length(wuy_dict[x][wuy_flags[x].!="M"]) for x in keys(wuy_dict)]
    # wuy_mean_day[wuy_mean_day.==Inf]=0

    # flag the deviations based on the vectors
    wux_dev= [x=>std(wux_dict[x][wux_flags[x].!="M"]) for x in keys(wux_dict)]
    #wux_dev = [x=>std(wux_dict[x]) for x in keys(wux_dict)]

    # flag the deviations based on the vectors
    wuy_dev= [x=>std(wuy_dict[x][wuy_flags[x].!="M"]) for x in keys(wuy_dict)]
    #wuy_dev = [x=>std(wuy_dict[x]) for x in keys(wuy_dict)]

    # mean wind is when the mean flags are not missing
    mean_wind= [x=>sum(array_mean[x][mean_flags[x].!="M"])/length(array_mean[x][mean_flags[x].!="M"]) for x in keys(array_mean)]
    #mean_wind = [x=>mean(array_mean[x]) for x in keys(array_mean)]
    
    # maximum gust should be fine on its own since it's looking for the max
    max_gust = [x=>maximum(array_max[x]) for x in keys(array_max)]

    # here we make the assumption that if the x flag is missing, the y is probably also missing, for getting the length of all
    wspd = [x=>windspeed(wux_sums[x], wuy_sums[x])/length(wux_dict[x][wux_flags[x].!="M"]) for x in keys(wux_dict)]

    # with the direction, a 0 direction will not matter, this is a resultant direction of the day
    wdir = [x=>convention(winddirection(wux_sums[x], wuy_sums[x])) for x in keys(wux_dict)]
    # with direction deviation, do not include the 0's as they will affect it
    wdirdev = [x=>std(array_flux[x][flux_flags[x].!="M"]) for x in keys(array_flux)]

    wair_snc_mean = [x=>mean(array_temp[x][temp_flags[x].!="M"]) for x in keys(array_temp)]
    wair_snc_std = [x=>std(array_temp[x][temp_flags[x].!="M"]) for x in keys(array_temp)]

    return wspd, max_gust, wdir, wdirdev, wux_mean_day, wuy_mean_day, wux_dev, wuy_dev, wair_snc_mean, wair_snc_std, mean_wind
end


function andrews_windspeed(primet_array, d2_pri, vanmet_array, d2_van)
    
    # flags on primet
    flag_results_wspd_snc_pri, flag_results_wspd_snc_pri_max, flag_results_wmag_snc_pri, flag_results_wdir_snc_pri, 
        flag_results_wdir_snc_pri_std, flag_results_wux_pri, flag_results_wux_pri_std, flag_results_wuy_pri,
        flag_results_wuy_pri_std, flag_results_temp_pri, flag_results_temp_pri_std = flag_primet(primet_array, d2_pri)

    # flags on vanmet
    flag_results_wspd_snc_van, flag_results_wspd_snc_van_max, flag_results_wmag_snc_van, flag_results_wdir_snc_van, 
        flag_results_wdir_snc_van_std, flag_results_wux_van, flag_results_wux_van_std, flag_results_wuy_van,
        flag_results_wuy_van_std, flag_results_temp_van, flag_results_temp_van_std= flag_vanmet(vanmet_array, d2_van)

    #= primet and vanmet wind metrics =#
    pri_wspd, pri_max_gust, pri_wdir, pri_wdirdev, pri_wux_mean, pri_wuy_mean, pri_wux_dev, pri_wuy_dev, pri_temp_mean, pri_temp_dev, pri_mean_wind = wind_iter(primet_array, d2_pri)
    van_wspd, van_max_gust, van_wdir, van_wdirdev, van_wux_mean, van_wuy_mean, van_wux_dev, van_wuy_dev, van_temp_mean, van_temp_dev, van_mean_wind = wind_iter(vanmet_array, d2_van)

    
    # key a dictionary for each
    list_primet_dates = sort(collect(keys(pri_wspd)))
    list_vanmet_dates = sort(collect(keys(van_wspd)))

    pri_mean_wind2 = collect([round(pri_mean_wind[x],3) for x in list_primet_dates])
    pri_mean_wind_2f = collect([flag_results_wspd_snc_pri[x] for x in list_primet_dates])
    pri_wspd_2 = collect([round(pri_wspd[x],3) for x in list_primet_dates])
    pri_wspd_2f = collect([flag_results_wmag_snc_pri[x] for x in list_primet_dates])
    pri_max_gust_2 = collect([round(pri_max_gust[x],3) for x in list_primet_dates])
    pri_max_gust_2f = collect([flag_results_wspd_snc_pri_max[x] for x in list_primet_dates])
    pri_wdir_2 = collect([round(pri_wdir[x],3) for x in list_primet_dates])
    pri_wdir_2f = collect([flag_results_wdir_snc_pri[x] for x in list_primet_dates])
    pri_wdirdev_2 = collect([round(pri_wdirdev[x],3) for x in list_primet_dates])
    pri_wdirdev_2f = collect([flag_results_wdir_snc_pri_std[x] for x in list_primet_dates])
    pri_wux_mean_2 = collect([round(pri_wux_mean[x],3) for x in list_primet_dates])
    pri_wux_mean_2f = collect([flag_results_wux_pri[x] for x in list_primet_dates])
    pri_wux_dev_2 = collect([round(pri_wux_dev[x],3) for x in list_primet_dates])
    pri_wux_dev_2f = collect([flag_results_wux_pri_std[x] for x in list_primet_dates])
    pri_wuy_mean_2 = collect([round(pri_wuy_mean[x],3) for x in list_primet_dates])
    pri_wuy_mean_2f = collect([flag_results_wuy_pri[x] for x in list_primet_dates])
    pri_wuy_dev_2 = collect([round(pri_wuy_dev[x],3) for x in list_primet_dates])
    pri_wuy_dev_2f = collect([flag_results_wuy_pri_std[x] for x in list_primet_dates])
    pri_temp_mean_2 = collect([round(pri_temp_mean[x],3) for x in list_primet_dates])
    pri_temp_mean_2f = collect([flag_results_temp_pri[x] for x in list_primet_dates])
    pri_temp_dev_2 = collect([round(pri_temp_dev[x],3) for x in list_primet_dates])
    pri_temp_dev_2f = collect([flag_results_temp_pri_std[x] for x in list_primet_dates])
    datestrings= [Dates.Date(x[1], x[2], x[3]) for x in list_primet_dates]

    dbcodearray = fill("MS043",length(list_primet_dates),1)
    entityarray = fill("24", length(list_primet_dates),1)
    sitecodearray = fill("PRIMET", length(list_primet_dates),1)
    methodarray = fill("WND011", length(list_primet_dates),1)
    heightarray = fill(1000, length(list_primet_dates),1)
    qcarray = fill("1A", length(list_primet_dates),1)
    probearray = fill("WNDPRI02", length(list_primet_dates),1)
    event_code = fill("NA",length(list_primet_dates),1)

    merged_primet = [dbcodearray entityarray sitecodearray methodarray heightarray qcarray probearray datestrings pri_mean_wind2 pri_mean_wind_2f pri_max_gust_2 pri_max_gust_2f pri_wspd_2 pri_wspd_2f pri_wdir_2 pri_wdir_2f pri_wdirdev_2 pri_wdirdev_2f pri_wux_mean_2 pri_wux_mean_2f pri_wux_dev_2 pri_wux_dev_2f pri_wuy_mean_2 pri_wuy_mean_2f pri_wuy_dev_2 pri_wuy_dev_2f pri_temp_mean_2 pri_temp_mean_2f pri_temp_dev_2 pri_temp_dev_2f event_code]

    writedlm("MS04324_v3.csv",merged_primet,',')

    van_mean_wind2 = collect([round(van_mean_wind[x],3) for x in list_vanmet_dates])
    van_mean_wind_2f = collect([flag_results_wspd_snc_van[x] for x in list_vanmet_dates])

    van_wspd_2 = collect([round(van_wspd[x],3) for x in list_vanmet_dates])
    van_wspd_2f = collect([flag_results_wmag_snc_van[x] for x in list_vanmet_dates])

    van_max_gust_2 = collect([round(van_max_gust[x],3) for x in list_vanmet_dates])
    van_max_gust_2f = collect([flag_results_wspd_snc_van_max[x] for x in list_vanmet_dates])
    van_wdir_2 = collect([round(van_wdir[x],3) for x in list_vanmet_dates])
    van_wdir_2f = collect([flag_results_wdir_snc_van[x] for x in list_vanmet_dates])
    van_wdirdev_2 = collect([round(van_wdirdev[x],3) for x in list_vanmet_dates])
    van_wdirdev_2f = collect([flag_results_wdir_snc_van_std[x] for x in list_vanmet_dates])
    van_wux_mean_2 = collect([round(van_wux_mean[x],3) for x in list_vanmet_dates])
    van_wux_mean_2f = collect([flag_results_wux_van[x] for x in list_vanmet_dates])
    van_wux_dev_2 = collect([round(van_wux_dev[x],3) for x in list_vanmet_dates])
    van_wux_dev_2f = collect([flag_results_wux_van_std[x] for x in list_vanmet_dates])
    van_wuy_mean_2 = collect([round(van_wuy_mean[x],3) for x in list_vanmet_dates])
    van_wuy_mean_2f = collect([flag_results_wuy_van[x] for x in list_vanmet_dates])
    van_wuy_dev_2 = collect([round(van_wuy_dev[x],3) for x in list_vanmet_dates])
    van_wuy_dev_2f = collect([flag_results_wuy_van_std[x] for x in list_vanmet_dates])
    van_temp_mean_2 = collect([round(van_temp_mean[x],3) for x in list_vanmet_dates])
    van_temp_mean_2f = collect([flag_results_temp_van[x] for x in list_vanmet_dates])
    van_temp_dev_2 = collect([round(van_temp_dev[x],3) for x in list_vanmet_dates])
    van_temp_dev_2f = collect([flag_results_temp_van_std[x] for x in list_vanmet_dates])
    datestrings= [Dates.Date(x[1], x[2], x[3]) for x in list_vanmet_dates]

    dbcodearray = fill("MS043",length(list_vanmet_dates),1)
    entityarray = fill("24", length(list_vanmet_dates),1)
    sitecodearray = fill("VANMET", length(list_vanmet_dates),1)
    methodarray = fill("WND011", length(list_vanmet_dates),1)
    heightarray = fill(1000, length(list_vanmet_dates),1)
    qcarray = fill("1A", length(list_vanmet_dates),1)
    probearray = fill("WNDVAN02", length(list_vanmet_dates),1)
    event_code = fill("NA",length(list_vanmet_dates),1)

    merged_vanmet = [dbcodearray entityarray sitecodearray methodarray heightarray qcarray probearray datestrings van_mean_wind2 van_mean_wind_2f van_max_gust_2 van_max_gust_2f van_wspd_2 van_wspd_2f van_wdir_2 van_wdir_2f van_wdirdev_2 van_wdirdev_2f van_wux_mean_2 van_wux_mean_2f van_wux_dev_2 van_wux_dev_2f van_wuy_mean_2 van_wuy_mean_2f van_wuy_dev_2 van_wuy_dev_2f van_temp_mean_2 van_temp_mean_2f van_temp_dev_2 van_temp_dev_2f event_code]

    writedlm("MS04324_2_v3.csv",merged_vanmet,',')
end

# "MAIN"
primet_array, vanmet_array, d2_pri, d2_van, dat, dir_mean, dir_std, wux_mean, wux_std, wuy_mean, wuy_std = read_in()
andrews_windspeed(primet_array, d2_pri, vanmet_array, d2_van)